// The Depot stack: the server at pkgs.c-137.me (the Worker `depot` and its R2
// bucket) and the GitHub settings that guard publishing to it. Deploy from
// this directory with `pnpm run deploy`; see README.md.
import * as Alchemy from "alchemy";
import { adopt } from "alchemy/AdoptPolicy";
import * as RemovalPolicy from "alchemy/RemovalPolicy";
import * as Cloudflare from "@alchemy.run/cloudflare";
import * as GitHub from "@alchemy.run/github";
import * as Effect from "effect/Effect";
import * as Layer from "effect/Layer";

const repo = { owner: "danielphan2003", repository: "depot" } as const

export const Bucket = Cloudflare.R2.Bucket("Bucket", { name: "depot", locationHint: "apac" })

// CI's bearer token for PUT, DELETE and listing. Alchemy generates it once
// and keeps it in its encrypted state, then gives the same value to the
// Worker and to the release environment.
export const UploadToken = Alchemy.makeRandom("UploadToken")

export type WorkerEnv = Cloudflare.InferEnv<typeof Worker>

export const Worker = Cloudflare.Worker("Pkgs", {
  name: "depot",
  main: "./src/index.ts",
  compatibility: { date: "2026-10-01" },
  domain: "pkgs.c-137.me",
  workersDev: false,
  observability: { enabled: true },
  env: { BUCKET: Bucket, UPLOAD_TOKEN: UploadToken },
})

export default Alchemy.Stack(
  "Depot",
  {
    providers: Layer.mergeAll(Cloudflare.providers(), GitHub.providers()),
    state: Cloudflare.state(),
  },
  Effect.gen(function* () {
    // The bucket holds every published package; the environment holds the
    // signing key, which Alchemy never sees. Neither goes away with the stack.
    const bucket = yield* Bucket.pipe(RemovalPolicy.retain())
    const worker = yield* Worker

    // Only main may deploy to release, so only main can read its secrets.
    const release = yield* GitHub.Environment("Release", {
      ...repo,
      name: "release",
      deploymentBranchPolicy: { customBranchPolicies: ["main"] },
    }).pipe(RemovalPolicy.retain())

    yield* GitHub.Secret("UploadTokenSecret", {
      ...repo,
      environment: release,
      name: "DEPOT_UPLOAD_TOKEN",
      value: yield* UploadToken,
    })

    // Every change to main goes through a pull request whose `ok` check (lint,
    // every build and every test) passed. No bypass, admins included.
    yield* GitHub.Ruleset("Main", {
      ...repo,
      name: "main",
      target: "branch",
      enforcement: "active",
      conditions: { include: ["~DEFAULT_BRANCH"] },
      bypassActors: [],
      rules: {
        deletion: true,
        nonFastForward: true,
        pullRequest: { requiredApprovingReviewCount: 0, allowedMergeMethods: ["squash"] },
        requiredStatusChecks: { checks: [{ context: "ok", integrationId: 15368 }] },
      },
    })

    return { url: worker.url, bucket: bucket.bucketName, environment: release.htmlUrl }
  }).pipe(adopt(true)),
)
