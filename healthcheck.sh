#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2016, Joyent, Inc.
#

if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi
set -o errexit
set -o pipefail


# Globals

NAME=$(basename $0)
VERSION=0.1.1


usage()
{
cat << EOF
healthcheck.sh: Requires 1 argument.

Note: This script assumes you have the Docker CLI, which requires the Triton CLI to be installed and configured for Docker.

Usage:
    ./healthcheck.sh IMAGE

Running a healthcheck on multiple images is not supported at this time.

EOF
}


while getopts "hV" option
do
    case $option in
        h)
	  usage
	  exit 0
	  ;;
	V)
	  echo "$(basename $0) $VERSION"
          exit 0
          ;;
    esac
done


if [[ -z $1 ]]
then
    usage
    exit 1
elif [[ -z $(docker search $1 | grep $1) ]]
then
    echo "healthcheck.sh: Error: No such image: "$1"."
    echo ""	
    echo "Use 'docker search IMAGE' to check if your image can be found and is valid."
    echo ""
    exit 1
else
    echo "Creating an instance of $1..."
    echo ""
fi



IMAGE_ID=$1
INSTANCE_ID=
IS_RUNNING=
NUM=

if [ "$IMAGE_ID" = "alpine" ]
then
    INSTANCE_ID=$(docker create alpine /bin/sh -c .//var/tmp/healthcheck_alpine.sh)
    IS_RUNNING=$true
else
    if [ "$IMAGE_ID" = "mysql" ]
    then
        INSTANCE_ID=$(docker run -d -e MYSQL_ROOT_PASSWORD=password mysql)
    elif [ "$IMAGE_ID" = "node" ]
    then
        INSTANCE_ID=$(docker run -dit $IMAGE_ID)
    else
        INSTANCE_ID=$(docker run -d $1)
    fi
    
    IS_RUNNING=$(docker inspect --format='{{ .State.Running }}' $INSTANCE_ID)

    echo "Finished provisioning, waiting 10 seconds for instance to configure..."
    echo ""
    sleep 10
fi


echo "Now running tests..."
echo ""
echo ""



if $IS_RUNNING
then
    docker cp ./resources/healthcheck_$IMAGE_ID.sh $INSTANCE_ID:/var/tmp/
    if [ "$IMAGE_ID" = "alpine" ]
    then
        INSTANCE_ID=$(docker start $INSTANCE_ID)
    else
        docker exec -it $INSTANCE_ID bash .//var/tmp/healthcheck_$IMAGE_ID.sh >/dev/null
    fi
    
    NUM=$(docker inspect --format='{{ .State.ExitCode }}' $INSTANCE_ID)
else
    echo "$IMAGE_ID failed to run correctly. Tests could not be initiated."
fi



# TODO: deal with DOCKER-845 bug not returning ExitCode of bash

if [ "$NUM" != "0" ] && $IS_RUNNING
then
    echo "$IMAGE_ID failed to run on `date`" >> error.log
    echo "$IMAGE_ID failed to execute the following:"
    echo ""

    while read line
    do
	echo "    $line"
    done < ./resources/healthcheck_$IMAGE_ID.sh
else
    echo "*** Healthcheck ran successfully. No problems were found. ***"
fi


echo ""
echo ""
echo "Stopping and removing the test instance..."
KILL_ID=$(docker kill $INSTANCE_ID)
REMOVE_ID=$(docker rm $INSTANCE_ID)

echo ""
echo "*** Healthcheck complete ***"
echo ""

