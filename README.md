# Development

```sh
docker compose build
docker compose up -d
docker compose exec web bash
```

```sh
rails arcdex:pull # to pull json from pokemontcg.io, about 60MB of data

# Indexing options:
rails arcdex:index_dir # to index everything in the ./data dir

DIR=some_other_dir rails arcdex:index_dir # to index everything in a specific dir

rails arcdex:index # to index ./data/base1.json

FIle=data/some_other.json rails arcdex:index # to index a speicific json

bin/web
```

Goto `localhost:3000` for the web and `http://localhost:8983/` for the Solr dashboard
