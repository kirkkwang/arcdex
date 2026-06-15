# Development

```sh
docker compose build
docker compose up -d
docker compose exec web bash
```

Go to `localhost:3000` for the web app and `http://localhost:8983/` for the Solr dashboard.

If `docker compose run --rm` fails on `bundle exec` (the local image can lag the
committed `Gemfile.lock`), run `bundle install` inside the running container
(`docker compose exec web bundle install`) instead of using a one-off container.

## Data

Solr is the system of record; there is no card database. Two sources feed it:

- **pokemontcg.io** for the main Pokémon TCG (`arcdex:pull`, about 60MB).
- **Bulbapedia** for Pokémon TCG Pocket (`arcdex:pull_bulbapedia`). Pocket card
  and set images are self-hosted on Cloudflare R2 (see `scripts/`).

The app does not track card prices.

### Daily sync (incremental)

`arcdex:sync` is the daily cron. It pulls and indexes only sets that are new or
have grown, from both sources, so most days it is a no-op. Set content can change
without the card count changing (a Bulbapedia correction, an errata), which the
count-based check cannot see, so force a refetch when needed:

```sh
FORCE=all rails arcdex:sync      # refetch and reindex every set
FORCE=a1,b3a rails arcdex:sync   # refetch and reindex specific ids/codes
```

A forced refetch that returns fewer cards than what is on disk is skipped by the
refuse-to-shrink guard in the pull tasks.

### Manual pull and index

```sh
rails arcdex:pull                          # all main-TCG sets from pokemontcg.io
rails arcdex:pull_set SET_ID=base1         # one main-TCG set
rails arcdex:pull_bulbapedia               # all Pocket expansions from Bulbapedia
rails arcdex:pull_bulbapedia_set SET=B3a   # one Pocket expansion

rails arcdex:index_dir                     # index everything under ./data
rails arcdex:index_dir DIR=data/pocket     # index a specific directory
rails arcdex:index FILE=data/base1.json    # index one file
rails arcdex:clear                         # delete all docs from Solr
```
