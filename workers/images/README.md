# arcdex-images Worker

Cloudflare Worker that fronts the `pokemon-tcg-pocket` R2 bucket on
`images.arcdex.dev`. On a missing object it serves a fallback **card back**
(`FALLBACK_KEY`) instead of a 404 — fixing broken images everywhere the URL is
used (gallery `<img>`, IIIF manifest, Mirador viewer), since card images sync to
R2 behind the Bulbapedia data.

## One-time setup
```bash
npm install -g wrangler        # or use: npx wrangler <cmd>
wrangler login                 # authorize your Cloudflare account
```

## Upload the fallback back to R2
The Worker reads the fallback from the bucket via the binding, so it must exist
in R2 (not just public/). Convert the Drive "Card Back.PNG" and upload:
```bash
magick "Card Back.PNG" -strip -resize '733x>' -quality 80 pokemon-tcg-pocket.webp
aws s3 cp pokemon-tcg-pocket.webp s3://pokemon-tcg-pocket/pokemon-tcg-pocket.webp \
  --profile r2 --endpoint-url https://<account>.r2.cloudflarestorage.com \
  --content-type image/webp
```
(Name the back by the game slug — `game_ssi.parameterize` — matching `FALLBACK_KEY`.)

## Deploy
```bash
cd workers/images
wrangler deploy
```
After deploy, the `[[routes]]` entry takes over `images.arcdex.dev/*`.

## Per-game later
For another game, copy this dir, point `bucket_name` at that game's bucket, set
its `FALLBACK_KEY`, and `wrangler deploy` — same `worker.js`. (Or, if games share
one bucket, add a key-prefix → back map in `worker.js`.)

## Notes
- Real images keep their stored `Cache-Control: immutable, max-age=31536000`.
- The fallback is served with `Cache-Control: max-age=300` so a card's real image
  appears within ~5 min of being synced (responses also carry `x-arcdex-fallback: 1`).
- Local check: `wrangler dev` runs it against the real R2 bucket.
