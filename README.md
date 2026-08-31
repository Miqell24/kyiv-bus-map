# Kyiv Public Transport — interactive map

Interactive, poster-grade map of the **surface** public transport network of
**Kyiv**: 96 bus lines, 42 trolleybus lines and 17 tram lines, the last of them
including the two Shvydkisnyi Tramvai light-rail routes — 1 374 poles,
3 419 km.

## Live

Local build on port 8174 (`npm run serve`).

Everything comes from ONE feed published on the **Kyiv open-data portal**. Its
own endpoint is a bare IP:port that is often unreachable from outside Ukraine,
so `download.sh` takes the Mobility Database's open daily mirror of the same
file, mdb-3230.

| mode | route_type | graph |
|---|---|---|
| buses | 3 | OSM roadways |
| trolleybuses | 11 | the same roadways, in green |
| trams | 0 | `railway=tram` + `light_rail` |

**The metro is not on this map.** Kyivskyi Metropoliten publishes no GTFS, and
this feed is the surface network only — the same call Göteborg's unnamed trains
and the Randstad's got.

**Line keys.** All three modes number from 1 here, so "11" is a bus AND a
trolleybus AND a tram. The trolleybuses ride the road graph, which means bus 11
and trolleybus 11 would land on the same key in the same cfg and be welded into
one line. They get a `Тб` prefix in the KEY and the trams a `Тм` — Sofia's rule,
for exactly Sofia's reason — and `LBL` prints the bare number the stop flag
shows. Nothing prints twice on a street: the colour says which mode it is.

The feed fills no `trip_headsign` anywhere, so directions are named after the
last stop of the drawn pattern (the repair the Swedish feeds needed first).

## Pipeline

`npm run download` fetches the feed and cuts the OSM extract. **The OSM
data comes from Geofabrik, not Overpass** — the public mirrors were answering
504 to every request on the day this map was built, even for a single small
city box — so `pipeline/pbf-tiles.py` (needs `pip3 install --user osmium`)
clips the tiles out of `ukraine-latest.osm.pbf`, writing exactly the JSON shape Overpass would
have returned, node ids included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graph) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view.
`npm run serve` hosts the map at <http://localhost:8174>.

Data: Портал даних Києва ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
