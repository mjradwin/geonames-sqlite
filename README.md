geonames-sqlite
===============

Import GeoNames.org data into a SQLite database for full-text search and autocomplete

## Example Usage

    wget http://download.geonames.org/export/dump/countryInfo.txt
    wget http://download.geonames.org/export/dump/admin1CodesASCII.txt
    wget http://download.geonames.org/export/dump/cities15000.zip
    unzip cities15000.zip
    ./geonames_cities_sqlite.pl geonames.sqlite3 \
        countryInfo.txt cities15000.txt admin1CodesASCII.txt

## Example queries

    sqlite> SELECT * FROM geoname_fulltext WHERE longname MATCH '"paris*"' ORDER BY population DESC;   
    2988507|Paris, Ile-de-France, France|Paris|Ile-de-France|France|2138551|48.85341|2.3488|Europe/Paris
    4717560|Paris, Texas, United States|Paris|Texas|United States|25171|33.66094|-95.55551|America/Chicago
    3023645|Cormeilles-en-Parisis, Ile-de-France, France|Cormeilles-en-Parisis|Ile-de-France|France|21973|48.97111|2.20491|Europe/Paris
    3725276|Fond Parisien, Ouest, Haiti|Fond Parisien|Ouest|Haiti|18256|18.50583|-71.97667|America/Port-au-Prince
    sqlite> 

## Autocomplete remote data source

Returns a JSON array of datums compatible with [Twitter typeahead.js](http://twitter.github.io/typeahead.js/).

For example, http://www.example.com/complete.php?q=san+jose

    [
       {
          "id":5392171,
          "value":"San Jose, California, United States",
          "admin1":"California",
          "asciiname":"San Jose",
          "country":"United States",
          "latitude":37.33939,
          "longitude":-121.89496,
          "timezone":"America\/Los_Angeles",
          "population":945942,
          "tokens":[
             "San",
             "Jose",
             "California",
             "United",
             "States"
          ]
       },
       {
          "id":1689395,
          "value":"San Jose del Monte, Central Luzon, Philippines",
          "admin1":"Central Luzon",
          "asciiname":"San Jose del Monte",
          "country":"Philippines",
          "latitude":14.81389,
          "longitude":121.04528,
          "timezone":"Asia\/Manila",
          "population":357828,
          "tokens":[
             "San",
             "Jose",
             "del",
             "Monte",
             "Central",
             "Luzon",
             "Philippines"
          ]
       },
       {
          "id":3621849,
          "value":"San Jose, Costa Rica",
          "admin1":"San Jose",
          "asciiname":"San Jose",
          "country":"Costa Rica",
          "latitude":9.93333,
          "longitude":-84.08333,
          "timezone":"America\/Costa_Rica",
          "population":335007,
          "tokens":[
             "San",
             "Jose",
             "Costa",
             "Rica"
          ]
       }
    ]
