#!/bin/bash
### WORK INPROGRESS
set -x
set -e

#DEPLOYMENT
export DOCKER_HOST="tcp://sp.int3.sonata-nfv.eu:2375"

#Removing the containers to refresh the versions
#set +x
set +e
docker rm -fv son-mongo
docker rm -fv son-monitor-postgres
docker rm -fv son-monitor-manager
#set -x
set -e

# MONGODB (CATALOGUE-REPOS)
# Starting
docker run -d -p 27017:27017 --name son-mongo mongo
while ! nc -z sp.int3.sonata-nfv.eu 27017; do
  sleep 1 && echo -n .; # waiting for mongo
done;

# MySQL (Monitoring)
# Starting
docker run -d -p 5433:5432 --name son-monitor-postgres -e POSTGRES_DB=monitoring -e POSTGRES_USER=monitoringuser -e POSTGRES_PASSWORD=sonata ntboes/postgres-uuid
while ! nc -z sp.int3.sonata-nfv.eu 5433; do
  sleep 1 && echo -n .; # waiting for postgres
done;

#Starting son-monitor to create the mysql databases:
docker run -d --name son-monitor-manager --add-host postgsql:10.30.0.112 --add-host prometheus:10.30.0.112 -p 8000:8000 -v /tmp/monitoring/mgr:/var/log/apache2 registry.sonata-nfv.eu:5000/son-monitor-manager
sleep 30


# Check if RabbitMQ is running
if ! nc -z sp.int3.sonata-nfv.eu 5672; then
  echo "Initializing RabbitMQ docker"
  docker run -d -p 5672:5672 --name son-broker rabbitmq:3
  while ! nc -z sp.int3.sonata-nfv.eu 5672; do
    sleep 1 && echo -n .; # waiting for rabbitmq
  done;
fi

# Check if NSR/VNFR repositories are running
if ! nc -z sp.int3.sonata-nfv.eu 4002; then
  echo "Initializing Repositories"
  docker run -d -p 4002:4002  --name son-catalogue-repos registry.sonata-nfv.eu:5000/son-catalogue-repos
  while ! nc -z sp.int3.sonata-nfv.eu 4002; do
    sleep 1 && echo -n .; # waiting for repositories
  done;
fi

# Check if SLM is running
is_running=`docker inspect -f {{.State.Running}} servicelifecyclemanagement`;
if [ "$is_running" = "false" ]; then
  echo "Initializing SLM"
  docker run -d --name servicelifecyclemanagement registry.sonata-nfv.eu:5000/servicelifecyclemanagement
  while [ "$is_running" = "false" ]; do
    sleep 1 && echo -n .; # waiting for SLM
    is_running=`docker inspect -f {{.State.Running}} servicelifecyclemanagement`;
  done
fi

export DOCKER_HOST="unix:///var/run/docker.sock"
