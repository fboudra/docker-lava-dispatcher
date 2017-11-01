#!/bin/sh

set -e

export LANG=C

image=docker-lava-dispatcher
docker build --pull --tag=$image .
