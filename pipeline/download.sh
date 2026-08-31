#!/usr/bin/env bash
# Downloads input data: the Kyiv GTFS, the OSM extract, MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# The Kyiv open-data portal publishes the surface network (bus, trolleybus,
# tram) as GTFS. Its own endpoint is a bare IP:port that is often unreachable
# from outside Ukraine, so the download takes the Mobility Database's open
# daily mirror of the same file, mdb-3230.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm/tiles web/vendor

# pyosmium does the cutting; it is the one dependency outside Node here.
need_osmium () {
  python3 -c "import osmium" 2>/dev/null && return 0
  echo "brak pakietu osmium — zainstaluj: pip3 install --user osmium" >&2
  return 1
}

# 1) GTFS
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== Kyiv GTFS =="
  curl -fL --retry 3 --max-time 600 -o data/kyiv-gtfs.zip \
    "https://files.mobilitydatabase.org/mdb-3230/latest.zip"
  unzip -o data/kyiv-gtfs.zip -d data/gtfs
fi

# 2) OSM — from the Geofabrik extract, not Overpass.
#    3 x 3 road tiles plus the tram network, out of the Ukrainian Geofabrik
#    extract; lviv-bus-map hard-links the same file.
#    pipeline/pbf-tiles.py cuts the tiles out of the .pbf and writes exactly the
#    JSON shape Overpass would have returned (ways with tags, NODE IDS and
#    geometry — buildGraph silently drops ways without el.nodes).
if [ ! -f data/osm/tiles/t9.json ] || [ ! -f data/osm/kyiv-rail.json ]; then
  need_osmium
  if [ ! -f data/ukraine-latest.osm.pbf ]; then
    echo "== Geofabrik ukraine-latest.osm.pbf =="
    curl -fL --retry 5 --retry-delay 5 -C - --max-time 3600 -o data/ukraine-latest.osm.pbf \
      "https://download.geofabrik.de/europe/ukraine-latest.osm.pbf"
  fi
  echo "== cutting OSM tiles out of the extract =="
  python3 pipeline/pbf-tiles.py
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs data/osm 2>/dev/null || true
