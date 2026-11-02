#!/usr/bin/env bash
# repo.sh sign <target> <file>...    sign package files (arch, fedora)
# repo.sh index <target> <root>      write the signed repository indices
#
# <root> mirrors the bucket layout (arch/x86_64/..., debian/..., fedora/...).
# Both use the secret key in $GNUPGHOME whose fingerprint is $DEPOT_KEY.
# Neither runs package code: they read package metadata only.
source "$(dirname "$0")/lib.sh"

[[ -n ${DEPOT_KEY:-} ]] || die "DEPOT_KEY (signing key fingerprint) is not set"

sign() {
  local file
  for file in "$@"; do
    case $family in
      arch) gpg --batch --yes --no-armor -u "$DEPOT_KEY" --detach-sign "$file" ;;
      fedora)
        rpmsign --define "_gpg_name $DEPOT_KEY" --define "_openpgp_sign_id $DEPOT_KEY" \
          "$([[ ${DEPOT_RESIGN:-} == 1 ]] && echo --resign || echo --addsign)" "$file" >/dev/null
        ;;
      debian) ;; # apt checks .deb files against the signed Release file
    esac
  done
}

# Newest file per package name in a directory of package files.
newest_per_name() {
  local -A best_file best_ver
  local file name ver
  while IFS= read -r -d '' file; do
    read -r name ver < <(pkg_meta "$family" "$file")
    if [[ -z ${best_ver[$name]:-} ]] || vergt "$family" "$ver" "${best_ver[$name]}"; then
      best_ver[$name]=$ver best_file[$name]=$file
    fi
  done < <(find "$1" "${@:2}" -print0)
  printf '%s\n' "${best_file[@]}"
}

index_arch() {
  local dir=$root/$repo_dir
  mkdir -p "$dir"
  rm -f "$dir"/depot.{db,files}*
  mapfile -t pkgs < <(newest_per_name "$dir" -maxdepth 1 -name '*.pkg.tar.*' ! -name '*.sig')
  [[ ${#pkgs[@]} -gt 0 ]] || { log "no arch packages"; return; }
  repo-add --sign --key "$DEPOT_KEY" "$dir/depot.db.tar.zst" "${pkgs[@]}"
  # R2 has no symlinks: store depot.db and depot.files as copies.
  local link
  for link in depot.db depot.db.sig depot.files depot.files.sig; do
    cp --remove-destination "$(readlink -f "$dir/$link")" "$dir/$link"
  done
}

index_debian() {
  local base=$root/debian dist=debian/dists/$codename
  local bin=$dist/main/binary-amd64
  mkdir -p "$base/${bin#debian/}" "$root/$repo_dir"
  (
    cd "$base"
    rm -f "dists/$codename"/{Release,InRelease,Release.gpg}
    apt-ftparchive --arch amd64 packages "pool/$codename/main" >"${bin#debian/}/Packages"
    gzip -9nkf "${bin#debian/}/Packages"
    apt-ftparchive \
      -o APT::FTPArchive::Release::Origin=depot \
      -o APT::FTPArchive::Release::Label=depot \
      -o APT::FTPArchive::Release::Suite="$codename" \
      -o APT::FTPArchive::Release::Codename="$codename" \
      -o APT::FTPArchive::Release::Architectures=amd64 \
      -o APT::FTPArchive::Release::Components=main \
      release "dists/$codename" >Release.tmp
    mv Release.tmp "dists/$codename/Release"
    gpg --batch --yes -u "$DEPOT_KEY" --clearsign -o "dists/$codename/InRelease" "dists/$codename/Release"
    gpg --batch --yes -u "$DEPOT_KEY" -abs -o "dists/$codename/Release.gpg" "dists/$codename/Release"
  )
}

index_fedora() {
  local dir=$root/$repo_dir
  mkdir -p "$dir"
  rm -rf "$dir/repodata"
  createrepo_c --quiet "$dir"
  gpg --batch --yes -u "$DEPOT_KEY" --armor --detach-sign -o "$dir/repodata/repomd.xml.asc" "$dir/repodata/repomd.xml"
}

case ${1:-} in
  sign)
    [[ $# -ge 2 ]] || die "usage: repo.sh sign <target> <file>..."
    target_info "$2"
    sign "${@:3}"
    ;;
  index)
    [[ $# -eq 3 ]] || die "usage: repo.sh index <target> <root>"
    target_info "$2"
    root=$3
    "index_$family"
    ;;
  *) die "usage: repo.sh sign|index <target> ..." ;;
esac
