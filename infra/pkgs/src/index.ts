// depot's package server. GET and HEAD serve objects from the R2 bucket to
// anyone: the repositories are signed, so the transport does not need to be
// trusted. PUT, DELETE and `GET /?list` need the upload token.

import type { WorkerEnv as DepotEnv } from "../alchemy.run.ts"

// Package files never change once published. Everything else (indices,
// signatures, repodata, the key) can change on the next publish.
const packagePattern = /\.(pkg\.tar\.zst|deb|rpm)$/

const encoder = new TextEncoder()

const digest = async (value: string) => crypto.subtle.digest("SHA-256", encoder.encode(value))

const authorized = async (request: Request, env: DepotEnv) => {
  const header = request.headers.get("authorization") ?? ""
  if (!env.UPLOAD_TOKEN || !header.startsWith("Bearer ")) return false
  const [given, expected] = await Promise.all([digest(header.slice(7)), digest(env.UPLOAD_TOKEN)])
  return crypto.subtle.timingSafeEqual(given, expected)
}

// Object keys are plain relative paths: no empty, "." or ".." segments.
const validKey = (key: string) =>
  key.length > 0 && key.length <= 512 && key.split("/").every((part) => part !== "" && part !== "." && part !== "..")

const text = (body: string, status = 200) =>
  new Response(body + "\n", { status, headers: { "content-type": "text/plain; charset=utf-8" } })

const list = async (url: URL, env: DepotEnv) => {
  const result = await env.BUCKET.list({
    prefix: url.searchParams.get("prefix") || undefined,
    cursor: url.searchParams.get("cursor") || undefined,
    limit: 1000,
  })
  return Response.json({
    objects: result.objects.map(({ key, size, etag }) => ({ key, size, etag })),
    cursor: result.truncated ? result.cursor : null,
  })
}

const serve = async (request: Request, key: string, env: DepotEnv) => {
  let object: R2Object | R2ObjectBody | null
  try {
    object = await env.BUCKET.get(key, { range: request.headers, onlyIf: request.headers })
  } catch {
    // R2 throws on a range it cannot satisfy, such as a resumed download
    // that was already complete.
    const head = await env.BUCKET.head(key)
    if (head === null) return text("not found", 404)
    return new Response(null, { status: 416, headers: { "content-range": `bytes */${head.size}` } })
  }
  if (object === null) return text("not found", 404)

  const headers = new Headers()
  object.writeHttpMetadata(headers)
  headers.set("etag", object.httpEtag)
  headers.set("accept-ranges", "bytes")
  headers.set("cache-control", packagePattern.test(key) ? "public, max-age=86400" : "no-cache")

  if (!("body" in object)) {
    // A failed If-None-Match or If-Modified-Since means "not modified"; a
    // failed If-Match or If-Unmodified-Since means the precondition failed.
    const cacheCheck = request.headers.has("if-none-match") || request.headers.has("if-modified-since")
    return new Response(null, { status: cacheCheck ? 304 : 412, headers })
  }

  const asked = /^bytes=(\d+)-/.exec(request.headers.get("range") ?? "")
  if (asked && Number(asked[1]) >= object.size) {
    return new Response(null, { status: 416, headers: { "content-range": `bytes */${object.size}` } })
  }

  let status = 200
  const range = object.range
  if (request.headers.has("range") && range) {
    // R2 may report a range as {offset, length} with suffix present but
    // undefined, so test the values rather than the keys.
    const suffix = "suffix" in range ? range.suffix : undefined
    const offset = "offset" in range ? range.offset : undefined
    const given = "length" in range ? range.length : undefined
    // A suffix longer than the object means the whole object.
    const start = typeof suffix === "number" ? Math.max(0, object.size - suffix) : (offset ?? 0)
    const length = typeof suffix === "number" ? object.size - start : (given ?? object.size - start)
    headers.set("content-range", `bytes ${start}-${start + length - 1}/${object.size}`)
    headers.set("content-length", String(length))
    status = 206
  } else {
    headers.set("content-length", String(object.size))
  }
  return new Response(request.method === "HEAD" ? null : object.body, { status, headers })
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    let key: string
    try {
      key = decodeURIComponent(url.pathname.slice(1))
    } catch {
      return text("bad path", 400)
    }

    if (request.method === "GET" || request.method === "HEAD") {
      if (key === "") {
        if (!url.searchParams.has("list")) return text("depot: signed package repositories (arch, debian, fedora)")
        if (!(await authorized(request, env))) return text("unauthorized", 401)
        return list(url, env)
      }
      if (!validKey(key)) return text("bad path", 400)
      return serve(request, key, env)
    }

    if (request.method === "PUT" || request.method === "DELETE") {
      if (!(await authorized(request, env))) return text("unauthorized", 401)
      if (!validKey(key)) return text("bad path", 400)
      if (request.method === "DELETE") {
        await env.BUCKET.delete(key)
        return new Response(null, { status: 204 })
      }
      if (request.body === null) return text("empty body", 400)
      await env.BUCKET.put(key, request.body, {
        httpMetadata: { contentType: request.headers.get("content-type") ?? "application/octet-stream" },
      })
      return new Response(null, { status: 201 })
    }

    return text("method not allowed", 405)
  },
} satisfies ExportedHandler<DepotEnv>
