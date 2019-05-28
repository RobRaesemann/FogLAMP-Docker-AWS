
# FogLAMP Docker AWS Imagee

## To test locally
#### Create the volume for FogLAMP data
```
docker create -v /usr/local/foglamp/data --name foglamp-data jea-foglamp-docker-aggregator-node:latest /bin/true
```

#### Run detached with autorestart
```
docker run --volumes-from foglamp-data -d -p 8081:8081 -p 80:80 -p 1995:1995 jea-foglamp-docker-aggregator-node:latest
```

#### Run interactively
```
docker run --volumes-from foglamp-data -it -p 8081:8081 -p 80:80 -p 1995:1995 jea-foglamp-docker-aggregator-node:latest /bin/bash
```

#### Attach interactively to detached session
```
docker exec -it foglamp /bin/bash
```

#### View logs
```
docker exec logs <id>
```