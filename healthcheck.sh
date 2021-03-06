#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

set -eo pipefail

usage() {
cat << EOF
Usage:
    ./healthcheck.sh [OPTIONS...] IMAGE_TYPE IMAGE

      IMAGE                     Name of the image as shown in the Docker Hub, e.g. 'joyent_dev/ubuntu'
      IMAGE_TYPE                The type of image, e.g. 'mongo', 'node', 'ubuntu'

Options:
      -v VERSION                Specify version of the image being checked.
      -t SECONDS                Specify number of seconds after an image is provisioned to begin
                                running the healthcheck tests. Default is 10 seconds.
Common options:
      -V                        Display healthcheck script version.
      -h                        Display this usage help.

A log showing successful/failed healthchecks can be found in the same directory as this script (after it is run for the first time).

Note: This script assumes you have the Docker CLI, which requires the Triton CLI to be installed and configured for Docker.

EOF
}


NAME=$(basename $0)
VERSION=0.3.1
IMAGE=
REPO=
IMAGE_VERSION=latest
DELAY=10
RETRIES=0
INSTANCE=
IS_RUNNING=false
EXIT_CODE=


while getopts "i:v:t:hV" OPTION; do
    case $OPTION in
        v)
          IMAGE_VERSION=$OPTARG
          ;;
        t)
          if [[ $OPTARG =~ ^[0-9]+$ ]]; then
              TIME_DELAY=$OPTARG
          else
              echo "healthcheck.sh: Error: -t flag takes an integer parameter."
              echo ""
              usage
              exit 1
          fi
          ;;
        V)
          echo "$(basename $0) $VERSION"
          exit 0
          ;;
        h)
          usage
          exit 0
          ;;
        *)
          echo "healthcheck.sh: Error: Invalid or insufficient parameters."
          echo ""
          usage
          exit 0
          ;;
    esac
done

shift $(($OPTIND - 1))
REPO=$1
IMAGE=$2


if [[ -z $IMAGE ]] || [[ -z $REPO ]]; then
    echo "healthcheck.sh: Healthcheck requires at least 2 arguments."
    echo ""
    usage
    exit 1
elif [[ -z $(docker search $IMAGE | grep $IMAGE | awk '{print $1}' | grep "^$IMAGE$") ]]; then
    echo "healthcheck.sh: Error: Could not find the image "$IMAGE"."
    echo ""	
    echo "Use 'docker search IMAGE' to check if your image can be found and is valid."
    echo ""
    exit 1
else
    echo "Creating an instance using the image: $IMAGE (ver. $IMAGE_VERSION)..."
    echo ""
fi


if [[ $REPO == "alpine" ]]; then
    INSTANCE=$(docker create $IMAGE:$IMAGE_VERSION /bin/sh -c .//var/tmp/alpine)
    IS_RUNNING=true
else
    if [[ $REPO == "mysql" ]]; then
        INSTANCE=$(docker run -d -e MYSQL_ROOT_PASSWORD=password $IMAGE:$IMAGE_VERSION)
    elif [[ $REPO == "node" ]]; then
        INSTANCE=$(docker run -dit $IMAGE:$IMAGE_VERSION)
    else
        INSTANCE=$(docker run -d $IMAGE:$IMAGE_VERSION)
    fi
    
    IS_RUNNING=$(docker inspect --format='{{ .State.Running }}' $INSTANCE)

    echo "Finished provisioning, waiting $DELAY seconds for instance to configure..."
    echo ""
    sleep $DELAY
fi

echo "Now running tests..."
echo ""
echo ""


if [[ $IS_RUNNING ]]; then
    docker cp ./resources/$REPO $INSTANCE:/var/tmp/

    if [[ $REPO == "alpine" ]]; then
        INSTANCE=$(docker start $INSTANCE)
    else
        docker exec -it $INSTANCE bash .//var/tmp/$REPO &>/dev/null || FAILED=true
    fi

    EXIT_CODE=$(docker inspect --format='{{ .State.ExitCode }}' $INSTANCE)

    if [[ $EXIT_CODE != 0 ]] || [[ $FAILED ]]; then
        echo "$IMAGE (ver. $IMAGE_VERSION) failed the healthcheck on `date`" >> healthcheck.log
        echo "" >> healthcheck.log
        echo "$IMAGE (ver. $IMAGE_VERSION) failed to execute the following:"
        echo ""
        while read line; do
            echo "    $line"
        done < ./resources/$IMAGE_TYPE
    else
        echo "$IMAGE (ver. $IMAGE_VERSION) passed the healthcheck on `date`" >> healthcheck.log
        echo "" >> healthcheck.log
        echo "  * * *  Healthcheck ran successfully. No problems were found.  * * *"
    fi
else
    echo "$IMAGE failed to run. Tests could not be initiated."
    echo "$IMAGE (ver. $IMAGE_VERSION) failed the healthcheck on `date`" >> healthcheck.log
    echo "" >> healthcheck.log
fi


echo ""
echo ""
echo "Stopping and removing the test instance..."
INSTANCE=$(docker kill $INSTANCE)
INSTANCE=$(docker rm $INSTANCE)
echo ""
echo ""
echo "  * * *  Healthcheck complete  * * *"
echo ""
echo ""
