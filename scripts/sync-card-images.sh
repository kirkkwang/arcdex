#!/usr/bin/env bash
#
# sync-card-images.sh — local, manual image pipeline for arcdex card images.
#
# Takes a folder of card images you've downloaded from the Google Drive,
# resizes + converts each to webp, renames to the R2 key convention
# (downcase + .webp, e.g. B2a-001.PNG -> b2a-001.webp), and uploads to R2.
#
# This is the manual step before a fully automated sync. It assumes the Drive
# filenames are already the canonical "{SET}-{NUMBER}" and just need downcasing
# — no catalog validation, no padding normalization. Trust the Drive.
#
# Requirements: ImageMagick (with webp support) and the AWS CLI.
#
# AWS credentials resolve via the normal chain (AWS_PROFILE, ~/.aws/credentials,
# env vars, …) — you don't pass keys here. R2_BUCKET is always required;
# R2_ENDPOINT can be omitted if endpoint_url is set in your ~/.aws/config.
#
# Usage:
#   R2_BUCKET=... R2_ENDPOINT=https://<account>.r2.cloudflarestorage.com \
#   scripts/sync-card-images.sh <source-dir> [--dry-run] [--force]
#
#   # or, if your AWS profile already has the R2 endpoint + creds:
#   AWS_PROFILE=r2 R2_BUCKET=... scripts/sync-card-images.sh <source-dir>
#
# Options:
#   --dry-run   Show what would be converted/uploaded; touch nothing.
#   --force     Re-convert and re-upload even if the key already exists in R2.
#
# Tunables (env):
#   MAX_WIDTH=733     Downscale only if wider than this (cards are ~733x1024).
#   QUALITY=80        webp quality.
#   AWS_REGION=auto   R2 ignores region but the CLI wants one.
#   CACHE_CONTROL="public, max-age=31536000, immutable"
#
#
#
# EXAMPLE COMMAND:
# AWS_PROFILE=r2 \
# R2_BUCKET=pokemon-tcg-pocket \
# R2_ENDPOINT=https://example.r2.cloudflarestorage.com \
# scripts/sync-card-images.sh ~/Downloads/<your-set-folder>

set -euo pipefail

# --- R2/aws-cli interop: avoid the v2 checksum header that older R2 rejects ---
export AWS_REQUEST_CHECKSUM_CALCULATION="${AWS_REQUEST_CHECKSUM_CALCULATION:-when_required}"
export AWS_RESPONSE_CHECKSUM_VALIDATION="${AWS_RESPONSE_CHECKSUM_VALIDATION:-when_required}"

MAX_WIDTH="${MAX_WIDTH:-733}"
QUALITY="${QUALITY:-80}"
AWS_REGION="${AWS_REGION:-auto}"
CACHE_CONTROL="${CACHE_CONTROL:-public, max-age=31536000, immutable}"
R2_BUCKET="${R2_BUCKET:-}"
R2_ENDPOINT="${R2_ENDPOINT:-}"

DRY_RUN=0
FORCE=0
SRC=""

die() { echo "error: $*" >&2; exit 1; }

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

# --- args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    -h|--help) usage 0 ;;
    -*)        die "unknown option: $1" ;;
    *)         [[ -z "$SRC" ]] && SRC="$1" || die "unexpected argument: $1" ;;
  esac
  shift
done

[[ -n "$SRC" ]]        || usage 1
[[ -d "$SRC" ]]        || die "source dir not found: $SRC"

# --- preflight ---
if command -v magick >/dev/null 2>&1; then IM=magick
elif command -v convert >/dev/null 2>&1; then IM=convert
else die "ImageMagick not found (need 'magick' or 'convert')"; fi
"$IM" -list format 2>/dev/null | grep -qi 'webp' || die "ImageMagick has no webp support (brew install webp, or reinstall imagemagick with webp)"
command -v aws >/dev/null 2>&1 || die "aws CLI not found"

# Credentials resolve through the normal AWS chain (env vars, AWS_PROFILE,
# ~/.aws/credentials, etc.) — we don't require them as env vars here.
# Only the bucket is mandatory; the endpoint may instead live in ~/.aws/config.
AWS_ARGS=(--region "$AWS_REGION")
[[ -n "$R2_ENDPOINT" ]] && AWS_ARGS+=(--endpoint-url "$R2_ENDPOINT")

if [[ $DRY_RUN -eq 0 ]]; then
  [[ -n "$R2_BUCKET" ]] || die "R2_BUCKET is required"
  [[ -n "$R2_ENDPOINT" ]] || echo "note: R2_ENDPOINT not set — relying on endpoint_url from your AWS config/profile" >&2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

uploaded=0 skipped_exist=0 skipped_nomatch=0 failed=0

echo "==> source: $SRC"
echo "==> target: s3://${R2_BUCKET:-<dry>}  (max ${MAX_WIDTH}px, webp q${QUALITY})"
[[ $DRY_RUN -eq 1 ]] && echo "==> DRY RUN — nothing will be written"

while IFS= read -r -d '' f; do
  base="$(basename "$f")"
  name="${base%.*}"   # strip extension

  # only files that look like a card: "{SET}-{NUMBER}" (set may contain one hyphen, e.g. P-A)
  if [[ ! "$name" =~ ^[A-Za-z0-9]+(-[A-Za-z0-9]+)?-[0-9]+$ ]]; then
    echo "  skip (not a card filename): $base"
    skipped_nomatch=$((skipped_nomatch + 1))
    continue
  fi

  # The downcased Drive filename IS the canonical id (e.g. PROMO-A-001 -> promo-a-001).
  id="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  key="${id}.webp"

  if [[ $FORCE -eq 0 && $DRY_RUN -eq 0 ]] \
     && aws s3api head-object --bucket "$R2_BUCKET" --key "$key" \
          "${AWS_ARGS[@]}" >/dev/null 2>&1; then
    echo "  exists, skip: $key"
    skipped_exist=$((skipped_exist + 1))
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  would upload: $base -> $key"
    uploaded=$((uploaded + 1))
    continue
  fi

  out="$TMP/$key"
  if ! "$IM" "$f" -strip -resize "${MAX_WIDTH}x>" -quality "$QUALITY" "$out" 2>/dev/null; then
    echo "  CONVERT FAILED: $base" >&2
    failed=$((failed + 1))
    continue
  fi

  if aws s3 cp "$out" "s3://${R2_BUCKET}/${key}" \
       "${AWS_ARGS[@]}" \
       --content-type image/webp --cache-control "$CACHE_CONTROL" >/dev/null; then
    echo "  uploaded: $key"
    uploaded=$((uploaded + 1))
  else
    echo "  UPLOAD FAILED: $key" >&2
    failed=$((failed + 1))
  fi
  rm -f "$out"
done < <(find "$SRC" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0)

echo "------------------------------------------------------------"
echo "uploaded: $uploaded  already-present: $skipped_exist  non-card-skipped: $skipped_nomatch  failed: $failed"
[[ $failed -eq 0 ]] || exit 1
