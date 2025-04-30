# Development

```sh
docker compose build
docker compose up -d
docker compose exec web bash
```

```sh
rails arcdex:pull # to pull json from pokemontcg.io, about 60MB of data
DIR=data rails arcdex:index_dir # to index everything
# or
FIle=data/base1.json rails arcdex:index # to index just one set

bin/web
```

Goto `localhost:3000` for the web and `http://localhost:8983/` for the Solr dashboard
