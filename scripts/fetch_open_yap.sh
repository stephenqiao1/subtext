#!/usr/bin/env bash
# Gets Open Yap 1K onto a rented machine without copying AWS keys to it.
#
# Step 1, on the Mac (has the AWS keys):
#   bash scripts/fetch_open_yap.sh links
#     -> writes data/open-yap-1k/links.txt: one temporary download link per
#        file. Links stop working after 7 days. Treat the file as a secret
#        (anyone holding it can download the dataset); it is git-ignored.
#   Then copy links.txt to the rented machine (scp or rsync).
#
# Step 2, on the rented machine (no AWS keys needed):
#   bash scripts/fetch_open_yap.sh download links.txt /workspace/open-yap-1k
#     -> downloads every part, checks it against SHA256SUMS, unpacks it and
#        deletes the archive. Needs about 150 GB free. Safe to re-run: parts
#        already unpacked are skipped.
#   Optional: PARTS="0001 0079" to fetch only some parts; JOBS=8 downloads at once.
#
# The delivery folder on S3 is deleted by the provider 30 days after delivery.
set -euo pipefail

S3_PREFIX="${S3_PREFIX:-s3://tadc-dataset-deliveries/581171874915/open-yap-1k_2026-11-25_flac_4cd3fa4e_ee9b709f}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"

sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

case "$MODE" in
links)
  OUT="${2:-$ROOT/data/open-yap-1k/links.txt}"
  EXPIRES="${EXPIRES:-604800}"   # 7 days, the longest S3 allows
  mkdir -p "$(dirname "$OUT")"
  BUCKET="$(echo "$S3_PREFIX" | sed -E 's|s3://([^/]+)/.*|\1|')"
  # Links are only valid if signed for the bucket's own region.
  REGION="$(curl -sI "https://$BUCKET.s3.amazonaws.com/" | tr -d '\r' | awk -F': ' 'tolower($1)=="x-amz-bucket-region"{print $2}')"
  [ -n "$REGION" ] || { echo "Could not find the bucket's region." >&2; exit 1; }
  SUMS="$(aws s3 cp --only-show-errors "$S3_PREFIX/SHA256SUMS" -)"
  : > "$OUT"
  for f in SHA256SUMS $(echo "$SUMS" | awk '{print $2}'); do
    printf '%s\t%s\n' "$f" "$(aws s3 presign --region "$REGION" --expires-in "$EXPIRES" "$S3_PREFIX/$f")" >> "$OUT"
  done
  chmod 600 "$OUT"
  echo "Wrote $(wc -l < "$OUT" | tr -d ' ') links to $OUT (valid for $((EXPIRES / 3600)) hours)."
  ;;

download)
  LINKS="${2:?Usage: $0 download <links.txt> <destination folder>}"
  DEST="${3:?Usage: $0 download <links.txt> <destination folder>}"
  JOBS="${JOBS:-8}"
  LINKS="$(cd "$(dirname "$LINKS")" && pwd)/$(basename "$LINKS")"
  mkdir -p "$DEST/.parts"
  cd "$DEST"

  url_for() { awk -F'\t' -v f="$1" '$1==f{print $2}' "$LINKS"; }
  curl -fsS --retry 5 -o .parts/SHA256SUMS "$(url_for SHA256SUMS)"

  # One part: download, check, unpack, delete the archive, leave a marker.
  fetch_one() {
    local f="$1" url
    [ -e ".parts/$f.done" ] && return 0
    url="$(awk -F'\t' -v f="$f" '$1==f{print $2}' "$LINKS")"
    curl -fsS --retry 5 --retry-all-errors -C - -o ".parts/$f" "$url"
    (cd .parts && grep " $f\$" SHA256SUMS | { if command -v sha256sum >/dev/null 2>&1; then sha256sum -c --quiet -; else shasum -a 256 -c - >/dev/null; fi; })
    tar -xf ".parts/$f"
    rm ".parts/$f"
    touch ".parts/$f.done"
    echo "ok $f"
  }
  export -f fetch_one
  export LINKS

  WANT="$(awk '{print $2}' .parts/SHA256SUMS)"
  if [ -n "${PARTS:-}" ]; then
    WANT="$(for p in $PARTS; do echo "part-$p.tar"; done)"
  fi
  echo "$WANT" | xargs -P "$JOBS" -I{} bash -c 'fetch_one "$1"' _ {}

  echo "Done: $(find conversations -maxdepth 1 -type d -name 'conv_*' | wc -l | tr -d ' ') conversations in $DEST/conversations"
  ;;

*)
  echo "Usage: $0 links [links.txt]   |   $0 download <links.txt> <destination folder>" >&2
  exit 1
  ;;
esac
