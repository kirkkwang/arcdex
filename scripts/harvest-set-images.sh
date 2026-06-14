#!/usr/bin/env bash
#
# harvest-set-images.sh — manual set logo + symbol harvest for arcdex.
#
# Resolves a TCG Pocket expansion's logo and symbol on Bulbapedia, converts
# them to webp, and uploads to R2 as {setcode}-logo.webp / {setcode}-symbol.webp
# (lowercased) — the keys the BulbapediaCardAdapter's logo_url/symbol_url use.
#
# Bulbapedia naming conventions:
#   logo   -> File:{SetCode} Set Logo EN.png     (e.g. "B3a Set Logo EN.png")
#   symbol -> File:SetSymbol{SetName}.png        (spaces -> underscores)
#
# This is the manual companion to sync-card-images.sh — not wired into the pull.
#
# Requirements: ImageMagick (with webp), AWS CLI, curl, python3.
# AWS creds resolve via the normal chain (AWS_PROFILE, ~/.aws/credentials, …).
#
# Usage:
#   # one set:
#   R2_BUCKET=pokemon-tcg-pocket R2_ENDPOINT=https://<acct>.r2.cloudflarestorage.com \
#   AWS_PROFILE=r2 scripts/harvest-set-images.sh <setcode> "<Set Name>" [--dry-run] [--force]
#
#   # ALL sets (omit the set args) — enumerates every Pocket expansion from Bulbapedia:
#   AWS_PROFILE=r2 R2_BUCKET=pokemon-tcg-pocket R2_ENDPOINT=... scripts/harvest-set-images.sh
#
#   e.g. scripts/harvest-set-images.sh B3a "Paradox Drive"
#
# Tunables (env): MAX_WIDTH=600  QUALITY=85  AWS_REGION=auto

set -euo pipefail

export AWS_REQUEST_CHECKSUM_CALCULATION="${AWS_REQUEST_CHECKSUM_CALCULATION:-when_required}"
export AWS_RESPONSE_CHECKSUM_VALIDATION="${AWS_RESPONSE_CHECKSUM_VALIDATION:-when_required}"

API="https://bulbapedia.bulbagarden.net/w/api.php"
UA="arcdex/1.0 (https://arcdex.dev; kirk@notch8.com) set-image-harvest"
MAX_WIDTH="${MAX_WIDTH:-600}"
QUALITY="${QUALITY:-85}"
AWS_REGION="${AWS_REGION:-auto}"
CACHE_CONTROL="${CACHE_CONTROL:-public, max-age=31536000, immutable}"
R2_BUCKET="${R2_BUCKET:-}"
R2_ENDPOINT="${R2_ENDPOINT:-}"

DRY_RUN=0
FORCE=0
SETCODE=""
SETNAME=""

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    -h|--help) usage 0 ;;
    -*)        die "unknown option: $1" ;;
    *)
      if [[ -z "$SETCODE" ]]; then SETCODE="$1"
      elif [[ -z "$SETNAME" ]]; then SETNAME="$1"
      else die "unexpected argument: $1"; fi ;;
  esac
  shift
done

# 0 set args = harvest all sets; 2 = a single set; 1 is ambiguous.
if [[ -n "$SETCODE" && -z "$SETNAME" ]]; then
  die 'pass both <setcode> and "<Set Name>", or neither to harvest all sets'
fi

if command -v magick >/dev/null 2>&1; then IM=magick
elif command -v convert >/dev/null 2>&1; then IM=convert
else die "ImageMagick not found (need 'magick' or 'convert')"; fi
"$IM" -list format 2>/dev/null | grep -qi 'webp' || die "ImageMagick has no webp support (brew install webp)"
command -v aws >/dev/null 2>&1 || die "aws CLI not found"
command -v python3 >/dev/null 2>&1 || die "python3 not found"

AWS_ARGS=(--region "$AWS_REGION")
[[ -n "$R2_ENDPOINT" ]] && AWS_ARGS+=(--endpoint-url "$R2_ENDPOINT")

if [[ $DRY_RUN -eq 0 ]]; then
  [[ -n "$R2_BUCKET" ]] || die "R2_BUCKET is required"
  [[ -n "$R2_ENDPOINT" ]] || echo "note: R2_ENDPOINT not set — relying on AWS config" >&2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Resolve a File: title to its direct URL via the MediaWiki imageinfo API.
resolve_url() {
  curl -s --get "$API" \
    --data-urlencode "action=query" \
    --data-urlencode "titles=File:$1" \
    --data-urlencode "prop=imageinfo" \
    --data-urlencode "iiprop=url" \
    --data-urlencode "format=json" \
    -H "User-Agent: $UA" \
  | python3 -c "import sys,json; p=list(json.load(sys.stdin)['query']['pages'].values())[0]; print(p['imageinfo'][0]['url'] if 'imageinfo' in p else '')"
}

harvest() { # $1 = File title, $2 = R2 key
  local title="$1" key="$2"
  echo "==> $title -> $key"

  if [[ $FORCE -eq 0 && $DRY_RUN -eq 0 ]] \
     && aws s3api head-object --bucket "$R2_BUCKET" --key "$key" "${AWS_ARGS[@]}" >/dev/null 2>&1; then
    echo "    exists, skip"
    return
  fi

  local url; url="$(resolve_url "$title")"
  [[ -n "$url" ]] || { echo "    NOT FOUND on Bulbapedia" >&2; return 1; }
  echo "    source: $url"

  if [[ $DRY_RUN -eq 1 ]]; then echo "    (dry run)"; return; fi

  curl -s -o "$TMP/src" -H "User-Agent: $UA" "$url"
  "$IM" "$TMP/src" -strip -resize "${MAX_WIDTH}x>" -quality "$QUALITY" "$TMP/out.webp" \
    || { echo "    CONVERT FAILED" >&2; return 1; }
  aws s3 cp "$TMP/out.webp" "s3://${R2_BUCKET}/${key}" "${AWS_ARGS[@]}" \
    --content-type image/webp --cache-control "$CACHE_CONTROL" >/dev/null \
    && echo "    uploaded"
}

# Harvest logo + symbol for one set. Returns non-zero if either failed.
harvest_set() { # $1 = set code (as in the logo filename), $2 = set name
  local code="$1" name="$2" canon logo_code code_lc name_us rc=0
  # Promo logos are filed as "PA"/"PB", but ids + R2 keys follow the Drive
  # (promo-a/promo-b). Canonicalize for the key; keep the raw code for the logo.
  case "$code" in
    PA | Promo-A | promo-a) canon="Promo-A"; logo_code="PA" ;;
    PB | Promo-B | promo-b) canon="Promo-B"; logo_code="PB" ;;
    *)                      canon="$code"; logo_code="$code" ;;
  esac
  code_lc="$(printf '%s' "$canon" | tr '[:upper:]' '[:lower:]')"
  # MediaWiki file titles drop ':' (namespace sep), so "Deluxe Pack: ex" ->
  # SetSymbolDeluxe_Pack_ex.png. Strip colons, then spaces -> underscores.
  name_us="${name//:/}"
  name_us="${name_us// /_}"
  echo "### ${code} — ${name} (R2: ${code_lc})"
  harvest "${logo_code} Set Logo EN.png" "${code_lc}-logo.webp" || rc=1
  harvest "SetSymbol${name_us}.png" "${code_lc}-symbol.webp" || rc=1
  return "$rc"
}

# All TCG Pocket expansion page titles from Bulbapedia's category.
list_expansion_titles() {
  curl -s --get "$API" \
    --data-urlencode "action=query" \
    --data-urlencode "list=categorymembers" \
    --data-urlencode "cmtitle=Category:Pokémon TCG Pocket expansions" \
    --data-urlencode "cmlimit=500" \
    --data-urlencode "cmtype=page" \
    --data-urlencode "format=json" \
    -H "User-Agent: $UA" \
  | python3 -c "import sys,json;[print(m['title']) for m in json.load(sys.stdin).get('query',{}).get('categorymembers',[]) if m['title'].endswith('(TCG Pocket)')]"
}

# Set code from an expansion page's infobox setlogo (e.g. 'B3a Set Logo EN.png' -> 'B3a').
set_code_for() { # $1 = expansion page title
  curl -s --get "$API" \
    --data-urlencode "action=parse" \
    --data-urlencode "page=$1" \
    --data-urlencode "prop=wikitext" \
    --data-urlencode "format=json" \
    -H "User-Agent: $UA" \
  | python3 -c "
import sys, json, re
try:
    wt = json.load(sys.stdin)['parse']['wikitext']['*']
except Exception:
    print(''); sys.exit()
m = re.search(r'\|\s*setlogo\s*=\s*(\S+)', wt)
print(m.group(1) if m else '')
"
}

if [[ -z "$SETCODE" ]]; then
  # All sets: enumerate expansions, derive each code, harvest both images.
  rc=0
  while IFS= read -r title; do
    [[ -n "$title" ]] || continue
    name="${title% (TCG Pocket)}"
    code="$(set_code_for "$title")"
    if [[ -z "$code" ]]; then
      echo "### skip (no set code): $title" >&2
      rc=1
      continue
    fi
    harvest_set "$code" "$name" || rc=1
  done < <(list_expansion_titles)
  echo "done."
  exit "$rc"
else
  harvest_set "$SETCODE" "$SETNAME" || exit 1
  echo "done."
  exit 0
fi
