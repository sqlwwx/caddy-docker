#!/usr/bin/env sh
docker build --build-arg \
  plugins=git,jwt \
  -t sqlwwx/caddy-jwt:latest .
