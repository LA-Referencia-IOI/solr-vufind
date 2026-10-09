# Solr 9.11 for VuFind 11

Apache Solr 9.11.0 Docker environment for the VuFind 11 cores:
`biblio`, `authority`, `reserves`, and `website`.

## Requirements

- Docker Engine with the Docker Compose plugin.
- A user permitted to run `docker` (for example, a member of the `docker`
  group); the script does not need to be run with `sudo`.

## Usage

Always use the script: it prepares the configuration, libraries, and persistent
directory before starting the container.

```sh
./solr.sh start
./solr.sh restart
./solr.sh stop
```

The service is available at `http://localhost:8983/solr`. The following
variables can be set before running the script:

```sh
SOLR_PORT=8984 SOLR_HEAP=4g ./solr.sh start
```

## Persistent data

Compose mounts `./volume/solr` at `/var/solr` inside the container. Check the
effective mount when needed:

```sh
docker inspect solr-9-11 --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
```

The output must contain `<repository-directory>/volume/solr -> /var/solr`. If
it points somewhere else, recreate the container with `./solr.sh start`.

## Upgrading from Solr 10

Indexes created with Solr/Lucene 10 cannot be opened by Solr 9.11. Back up any
required data, remove incompatible persisted indexes, and reindex VuFind. The
script does not copy indexes, spell-check data, or transaction logs from the
`vufind/` tree into the runtime volume.

## Diagnostics

To follow startup logs:

```sh
docker logs -f --tail 100 solr-9-11
```

If the container reports that it cannot write to `/var/solr`, ensure that the
mount above maps to `./volume/solr` and that this directory is writable by the
user running Compose.
