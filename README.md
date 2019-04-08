# Pentaho 7.0 Docker Image

## What is Pentaho?

[Pentaho](http://www.pentaho.com/) is a Business Intelligence (BI) software
company that offers Pentaho Business Analytics, a suite of open source products
which provide data integration, OLAP services, reporting, dashboarding, data
mining and ETL capabilities.

## What is this?

Pentaho has [clearly
stated](https://support.pentaho.com/hc/en-us/articles/210384343-Automated-deployment-solutions-Docker-Puppet-Chef-etc-)
that they will not be providing automated deployment solutions for their
products. This is a problem since the deployment process is quite
complicated.This docker project provides a much simpler deployment mechanism. It
is not perfect, but with your help it can get better every day. :-)

It is based on some really splendid work done by [Wellington
Marinho](https://github.com/wmarinho/docker-pentaho).

## Requirements
- [PostgreSQL](https://www.postgresql.org/) 9.4
  - `postgres:9.4-alpine` worked nicely for me

## How to run

- Start a PostgreSQL server
```
docker run -d -p 5432:5432 --name postgres postgres:9.4-alpine
```

- Run once for testing and auto-clean container
```
docker run --rm -it --link postgres:postgres \
-e PGHOST=postgres -e PGUSER=postgres -e PGPASSWORD= -p 8080:8080 ca0abinary/docker-pentaho
```

- Start in bash, prior to any scripts having executed, auto-clean (for debugging)
```
docker run --rm -it --link postgres:postgres \
-e PGHOST=postgres -e PGUSER=postgres -e PGPASSWORD= -p 8080:8080 \
--entrypoint bash ca0abinary/docker-pentaho
```

- Run as a service
```
docker run -d --link postgres:postgres \
-e PGHOST=postgres -e PGUSER=postgres -e PGPASSWORD= -p 8080:8080 \
ca0abinary/docker-pentaho
```

## HyperSQL

It's possible to run without PostgreSQL and only use the hsqldb.

If you want your data to be preserved in the event of container loss, you should
keep it in a data container or volume map.

- HSQLDB
- Jackrabbit stores files locally at `/opt/pentaho/server/pentaho-server/pentaho-solutions/system/jackrabbit/repository`

Example:
```
docker run --rm -it \
-v /mnt/nfs-share/pentaho/hsqldb:/opt/pentaho/server/pentaho-server/data/hsqldb \
-v /mnt/nfs-share/pentaho/repository:/opt/pentaho/server/pentaho-server/pentaho-solutions/system/jackrabbit/repository \
-p 8080:8080 ca0abinary/docker-pentaho
```

## Environment variables

- `PGHOST` The hostname or IP of the postgresql server
- `PGPORT` The port number of the postgreql service `(default 5432)`
- `PGDATABASE` The database name to use `(default postgres)`
- `PGUSER` The admin username (used for creating databases / database users) `(default pgadmin)`
- `PGPASSWORD` The admin password `(default pgadmin.)`

## Login Credentials

- `admin` - Administrator.
- `pat` - Business Analyst.
- `suzy` - Power User.
- `tiffany` - Report Author.

Default password is `password`.

## Docker Compose Examples

The simplest `docker-compose.yml` file would be:

```
version: "3"
services:
  # Pentaho BI
  pentaho:
    container_name: pentaho
    image: ca0abinary/docker-pentaho
    depends_on:
      - pentaho-pg
    ports:
      - "8080:8080"
    environment:
      - HOST=pentaho-pg
      - USER=pentaho
      - PASSWORD=password
    volumes:
      - pentaho-hsqldb-data:/opt/pentaho/server/pentaho-server/data/hsqldb
      - pentaho-jackrabbit-data:/opt/pentaho/server/pentaho-server/pentaho-solutions/system/jackrabbit/repository

  # PostgreSQL Database for Pentaho BI
  pentaho-pg:
    container_name: pentaho-pg
    image: postgres:9.4
    environment:
      - POSTGRES_USER=pentaho
      - POSTGRES_PASSWORD=password
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - pentaho-pg-data:/var/lib/postgresql/data/pgdata

# Data volumes
volumes:
  pentaho-hsqldb-data:
  pentaho-jackrabbit-data:
  pentaho-pg-data:
```

## Problems

Quartz and Hibernate continue to live on the internal
[HyperSQL](http://hsqldb.org/) database as despite changing the settings to work
with PostgreSQL using the provided documentation I'm not having success.
(`java.sql.SQLException: No suitable driver`)

The databases will be created in PostgreSQL, just not used.

Please feel free to examine the `scripts/setup_postgresql.sh` and post a PR if
you can fix it!

## See Also

- [Wellington
Marinho](https://github.com/wmarinho/docker-pentaho).
- [Pentaho 7.0 Docker Image](https://github.com/ca0abinary/docker-pentaho).
- [Pentaho 7.0 Documentation](https://help.pentaho.com/Documentation/7.0).
