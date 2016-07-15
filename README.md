# Docker Image Healthcheck

A shell script that does a basic healthcheck of a specified Docker image, provided the image type and its name as shown in the Docker Hub.

## Setup

You will need to have the [Docker CLI](https://docs.joyent.com/public-cloud/api-access/docker), which requires the [Triton CLI](https://docs.joyent.com/public-cloud/api-access/cloudapi) to be installed and configured for Docker.


## Usage

To run the healthcheck, run the script like so:
```bash
$ ./healthcheck.sh [OPTIONS...] IMAGE_TYPE IMAGE
```
If you wish to verify the image's name, use `docker search TERM`.

```bash
Usage:
      IMAGE                     Name of the image as shown in the Docker Hub, e.g. 'joyent_dev/ubuntu'
      IMAGE_TYPE                The type of image, e.g. 'mongo', 'node', 'ubuntu'

Options:
      -v VERSION                Specify version of the image being checked.
      -t SECONDS                Specify number of seconds after an image is provisioned to begin
                                running the healthcheck tests. Default is 10 seconds.
Common options:
      -V                        Display healthcheck script version.
      -h                        Display this usage help.
```

## Supported Image Types

Currently, the types of images that have healthcheck tests implemented are:
* MongoDB
* MySQL
* Node.js
* NGINX
* Alpine Linux


This does not mean only official Docker images are supported - you can test your own image as long as it is public on the Docker Hub!
For example:

```bash
$ ./healthcheck mongo  myrepo/mongo-centos
```


Support for additional images will be added as the script is developed.

