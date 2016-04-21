FROM tozd/meteor

RUN apt-get update -q -q && \
  apt-get install --yes --force-yes python

COPY ./docker/etc /etc
