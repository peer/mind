#/bin/bash -e

mkdir -p /srv/var/log/council
mkdir -p /srv/council/storage

docker run -d --restart=always --name council --hostname council -e ROOT_URL=http://council.cloyne.org -e MAIL_URL=mail.cloyne.net -e STORAGE_DIRECTORY=/storage -v /srv/var/hosts:/etc/hosts:ro -v /srv/var/log/council:/var/log/meteor -v /srv/council/storage:/storage mitar/council-app
