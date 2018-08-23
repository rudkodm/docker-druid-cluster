# Build and Run:

## Single Node Mode:
```sh
docker-compose build && docker-compose up
```


## Cluster Mode:
```sh
docker-compose -f docker-compose-cluster.yml build && docker-compose -f docker-compose-cluster.yml up
```


# Dependencies:
Therea is 1 external dependency on MS-SQL server instance required for Metastore
