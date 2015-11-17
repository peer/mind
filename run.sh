#!/bin/bash -e

# An example script to run the app in production. It uses data volumes under the $DATA_ROOT directory.
# By default /srv. It uses a MongoDB database, tozd/meteor-mongodb image which is automatically run as well.

NAME='council'
DATA_ROOT='/srv'
MONGODB_DATA="${DATA_ROOT}/${NAME}/mongodb/data"
MONGODB_LOG="${DATA_ROOT}/${NAME}/mongodb/log"

METEOR_LOG="${DATA_ROOT}/${NAME}/meteor/log"
METEOR_STORAGE="${DATA_ROOT}/${NAME}/meteor/storage"

SETTINGS="${DATA_ROOT}/${NAME}/run.settings"

mkdir -p "$MONGODB_DATA"
mkdir -p "$MONGODB_LOG"
mkdir -p "$METEOR_LOG"
mkdir -p "$METEOR_STORAGE"

touch "$SETTINGS"

if [ ! -s "$SETTINGS" ]; then
  echo "Set MONGODB_CREATE_PWD, MONGODB_ADMIN_PWD, MONGODB_OPLOGGER_PWD and export MONGO_URL, MONGO_OPLOG_URL environment variables in '$SETTINGS'."
  exit 1
fi

docker stop "${NAME}_mongodb" || true
sleep 1
docker rm "${NAME}_mongodb" || true
sleep 1
docker run --detach=true --restart=always --name "${NAME}_mongodb" --hostname "${NAME}_mongodb" --expose 27017 --volume /srv/var/hosts:/etc/hosts:ro --volume "${SETTINGS}:/etc/service/mongod/run.settings" --volume "${MONGODB_LOG}:/var/log/mongod" --volume "${MONGODB_DATA}:/var/lib/mongodb" tozd/meteor-mongodb:2.6

docker run --detach=true --restart=always --name council --hostname council --expose 3000 --env ROOT_URL=http://council.cloyne.org --env MAIL_URL=mail.cloyne.net --env STORAGE_DIRECTORY=/storage --volume /srv/var/hosts:/etc/hosts:ro --volume "${SETTINGS}:/etc/service/meteor/run.settings" --volume "${METEOR_LOG}:/var/log/meteor" --volume "${METEOR_STORAGE}:/storage" mitar/council-app
