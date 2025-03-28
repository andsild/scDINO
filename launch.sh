#!/usr/bin/env bash

set -xe
docker run --rm --name scdino --gpus  'device=1' --shm-size=2g --ulimit core=0 -v ${PWD}:/code -v /data/aml/:/data/aml -it pesktux/scdino:latest
