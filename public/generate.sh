#!/bin/bash -e

npm install -g cli-real-favicon

real-favicon generate favicon.json version.json .

mv manifest.json app-manifest.json
