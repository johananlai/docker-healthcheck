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
fi



IMAGE_ID=$1
INSTANCE_ID=

if [ "$IMAGE_ID" = "mysql" ]
then
	INSTANCE_ID=$(docker run -d -e MYSQL_ROOT_PASSWORD=password mysql:latest)
elif [ "$IMAGE_ID" = "node" ]
then
	INSTANCE_ID=$(docker run -dit $1)
else
	INSTANCE_ID=$(docker run -d $1)
fi



is_running=$(docker inspect --format='{{ .State.Running }}' $INSTANCE_ID)

if $is_running
then
	docker cp ./resources/healthcheck_$IMAGE_ID.sh $INSTANCE_ID:/var/tmp/
	docker exec -it $INSTANCE_ID bash .//var/tmp/healthcheck_$IMAGE_ID.sh >/dev/null
fi



# TODO: deal with DOCKER-845 bug not returning ExitCode of bash

num=$(docker inspect --format='{{ .State.ExitCode }}' $INSTANCE_ID)

if [ "$num" != "0" ] || ! [ "$is_running" ]
then
	echo "$IMAGE_ID failed to run on `date`" >> error.log
else
	echo ""
	echo "Healthcheck ran successfully. No problems were found."
	echo ""
fi


echo "Stopping and removing the test instance..."
KILL_ID=$(docker kill $INSTANCE_ID)
echo "..."
REMOVE_ID=$(docker rm $INSTANCE_ID)
echo "..."
sleep 1
echo "Complete!"

