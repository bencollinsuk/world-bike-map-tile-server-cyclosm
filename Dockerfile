FROM ubuntu:22.04 AS compiler-common
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ENV DEBIAN_FRONTEND=noninteractive
ENV AUTOVACUUM=on
ENV UPDATES=disabled
ENV REPLICATION_URL=https://planet.openstreetmap.org/replication/hour/
ENV MAX_INTERVAL_SECONDS=3600
ENV PG_VERSION 15
ENV DOWNLOAD_PBF=

# Based on
# https://switch2osm.org/serving-tiles/manually-building-a-tile-server-18-04-lts/

# Set up environment
ENV TZ=UTC
ENV AUTOVACUUM=on
ENV UPDATES=disabled
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 ca-certificates gnupg lsb-release locales \
 wget curl \
 git-core unzip unrar \
&& locale-gen $LANG && update-locale LANG=$LANG \
&& sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
&& wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
&& apt-get update && apt-get -y upgrade

# Install dependencies
RUN apt-get update \
  && apt-get install -y wget gnupg2 lsb-core apt-transport-https ca-certificates curl \
  && wget --quiet -O - https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get update \
  && apt-get install -y nodejs


# RUN sh -c 'echo  "deb http://us.archive.ubuntu.com/ubuntu jammy main multiverse" > /etc/apt/sources.list'

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  apache2 \
  apache2-dev \
  autoconf \
  build-essential \
  bzip2 \
  cmake \
  cron \
  fonts-dejavu-core \
  fonts-hanazono \
  fonts-noto-cjk \
  fonts-noto-hinted \
  fonts-noto-unhinted \
  gcc \
  gdal-bin \
  git-core \
  libagg-dev \
  libboost-filesystem-dev \
  libboost-system-dev \
  libbz2-dev \
  libcairo-dev \
  libcairomm-1.0-dev \
  libexpat1-dev \
  libfreetype6-dev \
  libgdal-dev \
  libgeos++-dev \
  libgeos-dev \
  libgeotiff-dev \
  libicu-dev \
  liblua5.3-dev \
  libmapnik-dev \
  libpq-dev \
  libproj-dev \
  libprotobuf-c-dev \
  libtiff5-dev \
  libtool \
  libxml2-dev \
  lua5.3 \
  make \
  mapnik-utils \
  osm2pgsql \
  osmium-tool \
  osmosis \
  postgresql-$PG_VERSION \
  postgresql-$PG_VERSION-postgis-3 \
  postgresql-$PG_VERSION-postgis-3-scripts \
  postgresql-contrib-$PG_VERSION \
  postgresql-server-dev-$PG_VERSION \
  postgis \
  protobuf-c-compiler \
  python3-mapnik \
  python3-lxml \
  python3-psycopg2 \
  python3-shapely \
  renderd \
  sudo \
  tar \
  unifont \
  unzip \
  wget \
  zlib1g-dev \
&& apt-get clean autoclean \
&& apt-get autoremove --yes \
&& rm -rf /var/lib/{apt,dpkg,cache,log}/

# Set up PostGIS
# RUN wget https://download.osgeo.org/postgis/source/postgis-3.1.1.tar.gz -O postgis.tar.gz \
#  && mkdir -p postgis_src \
#  && tar -xvzf postgis.tar.gz --strip 1 -C postgis_src \
#  && rm postgis.tar.gz \
#  && cd postgis_src \
#  && ./configure \
#  && make -j $(nproc) \
#  && make -j $(nproc) install \
#  && cd .. && rm -rf postgis_src

# Set up renderer user
RUN adduser --disabled-password --gecos "" renderer

# Install latest osm2pgsql
# RUN mkdir -p /home/renderer/src \
#  && cd /home/renderer/src \
#  && git clone -b master https://github.com/openstreetmap/osm2pgsql.git --depth 1 \
#  && cd /home/renderer/src/osm2pgsql \
#  && rm -rf .git \
#  && mkdir build \
#  && cd build \
#  && cmake .. \
#  && make -j $(nproc) \
#  && make -j $(nproc) install \
#  && mkdir /nodes \
#  && chown renderer:renderer /nodes \
#  && rm -rf /home/renderer/src/osm2pgsql

RUN apt install libapache2-mod-tile renderd

# Install mod_tile and renderd
# RUN mkdir -p /home/renderer/src \
#  && cd /home/renderer/src \
#  && git clone https://github.com/SomeoneElseOSM/mod_tile.git --depth 1 \
#  && cd mod_tile \
#  && rm -rf .git \
#  && ./autogen.sh \
#  && ./configure \
#  && make -j $(nproc) \
#  && make -j $(nproc) install \
#  && make -j $(nproc) install-mod_tile \
#  && ldconfig \
#  && cd ..

# Configure Noto Emoji font
# RUN mkdir -p /home/renderer/src \
# && cd /home/renderer/src \
# && git clone https://github.com/googlei18n/noto-emoji.git \
# && git -C noto-emoji checkout e0aa9412575fc39384efd39f90c4390d66bdd18f \
# && cp noto-emoji/fonts/NotoColorEmoji.ttf /usr/share/fonts/truetype/noto \
# && cp noto-emoji/fonts/NotoEmoji-Regular.ttf /usr/share/fonts/truetype/noto \
# && rm -rf noto-emoji

# Configure stylesheet
RUN mkdir -p /home/renderer/src \
 && cd /home/renderer/src \
 && git clone https://github.com/bencollinsuk/world-bike-map-cyclosm.git \
#  && git -C world-bike-map-cyclosm checkout e6f051f639ab1198c1a14e941cc0dd8a05d14d3b \
 && cd world-bike-map-cyclosm \
 && cp views.sql / \
 && rm -rf .git \
 && npm install -g carto@0.18.2 \
 && mkdir data \
 && cd data \
 && wget -O simplified-land-polygons.zip http://osmdata.openstreetmap.de/download/simplified-land-polygons-complete-3857.zip \
 && wget -O land-polygons.zip http://osmdata.openstreetmap.de/download/land-polygons-split-3857.zip \
 && unzip simplified-land-polygons.zip \
 && unzip land-polygons.zip \
 && rm /home/renderer/src/world-bike-map-cyclosm/data/*.zip \
 && cd .. \
 && sed -i 's/dbname: "osm"/dbname: "gis"/g' project.mml \
 && sed -i 's,http://osmdata.openstreetmap.de/download/simplified-land-polygons-complete-3857.zip,data/simplified-land-polygons-complete-3857/simplified_land_polygons.shp,g' project.mml \
 && sed -i 's,http://osmdata.openstreetmap.de/download/land-polygons-split-3857.zip,data/land-polygons-split-3857/land_polygons.shp,g' project.mml \
 && carto project.mml > mapnik.xml

COPY renderd.conf /etc/renderd.conf

# # Configure renderd
# RUN sed -i 's/renderaccount/renderer/g' /etc/renderd.conf \
#  && sed -i 's/\/truetype//g' /etc/renderd.conf \
#  && sed -i 's/hot/tile/g' /etc/renderd.conf \
#  && sed -i 's/openstreetmap-carto/world-bike-map-cyclosm/g' /etc/renderd.conf

# Configure Apache
RUN mkdir /var/lib/mod_tile \
 && chown renderer /var/lib/mod_tile \
 && mkdir /var/run/renderd \
 && chown renderer /var/run/renderd \
 && echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/conf-available/mod_tile.conf \
 && echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> /etc/apache2/conf-available/mod_headers.conf \
 && a2enconf mod_tile && a2enconf mod_headers
COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY security.conf /etc/apache2/conf-enabled/security.conf
RUN rm /var/www/html/index.html
COPY leaflet.html /var/www/html/index.html
COPY leaflet.js /var/www/html/
COPY leaflet.css /var/www/html/
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
 && ln -sf /dev/stderr /var/log/apache2/error.log

# Configure PostgreSQL
COPY postgresql.custom.conf.tmpl /etc/postgresql/$PG_VERSION/main/
RUN chown -R postgres:postgres /var/lib/postgresql \
 && chown postgres:postgres /etc/postgresql/$PG_VERSION/main/postgresql.custom.conf.tmpl \
 && echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf \
 && echo "host all all ::/0 md5" >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf

# Create volume directories
RUN mkdir -p /run/renderd/ \
  &&  mkdir  -p  /data/database/  \
  &&  mkdir  -p  /data/style/  \
  &&  mkdir  -p  /home/renderer/src/  \
  &&  chown  -R  renderer:  /data/  \
  &&  chown  -R  renderer:  /home/renderer/src/  \
  &&  chown  -R  renderer:  /run/renderd  \
  &&  mv  /var/lib/postgresql/$PG_VERSION/main/  /data/database/postgres/  \
  &&  mv  /var/cache/renderd/tiles/            /data/tiles/     \
  &&  chown  -R  renderer: /data/tiles \
  &&  ln  -s  /data/database/postgres  /var/lib/postgresql/$PG_VERSION/main             \
  &&  ln  -s  /data/tiles              /var/cache/renderd/tiles                \
;

# Copy update scripts
COPY openstreetmap-tiles-update-expire /usr/bin/
RUN chmod +x /usr/bin/openstreetmap-tiles-update-expire \
 && mkdir /var/log/tiles \
 && chmod a+rw /var/log/tiles \
 && ln -s /home/renderer/src/mod_tile/osmosis-db_replag /usr/bin/osmosis-db_replag \
 && echo "*  *    * * *   renderer    openstreetmap-tiles-update-expire\n" >> /etc/crontab

# Install trim_osc.py helper script
RUN mkdir -p /home/renderer/src \
 && cd /home/renderer/src \
 && git clone https://github.com/zverik/regional \
 && cd regional \
 && git checkout 889d630a1e1a1bacabdd1dad6e17b49e7d58cd4b \
 && rm -rf .git \
 && chmod u+x /home/renderer/src/regional/trim_osc.py

# Start running
COPY run.sh /
COPY indexes.sql /
ENTRYPOINT ["/run2.sh"]
CMD []
EXPOSE 80 5432
