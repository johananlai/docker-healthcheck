#!/bin/bash

for image in `ls ./resources`; do
    for image_name in `docker search -s 50 $image | awk '{print $1}' | tail -n+2`; do
        ./healthcheck.sh $image $image_name
    done
done
