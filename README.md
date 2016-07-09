# Docker Image Healthcheck
A shell script that does a basic healthcheck of a specified Docker image, writing into a log if errors are encountered.

## Setup
You will need to have the [Docker CLI](https://docs.joyent.com/public-cloud/api-access/docker), which requires the [Triton CLI](https://docs.joyent.com/public-cloud/api-access/cloudapi) to be installed and configured for Docker.


## Running the Tests
To run the healthcheck, run the script:
```sh
$ ./healthcheck.sh IMAGE
```

where IMAGE is the name of the Docker image you wish to test.

If you aren't sure about the image name, use
```sh
$ docker search TERM
```

## Supported Images
Currently, the images that have healthcheck tests implemented are:
* MongoDB
* MySQL
* Node.js
* NGINX

Additional images will be added as the script is developed.
