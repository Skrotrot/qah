#!/bin/bash
docker run --interactive --rm -v .:/data -w /data quay.io/coreos/butane:release\
       --pretty --strict -d butane/ < butane/qah.yaml > qah.ign