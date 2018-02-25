FROM tozd/meteor:ubuntu-xenial

ENV METEOR_STORAGE_CHOWN=

COPY ./docker/etc /etc
