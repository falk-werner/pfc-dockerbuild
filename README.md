# pfc-dockerbuild

Provides a docker file to create PFC firmware images.  
Please refer to [https://github.com/WAGO/pfc-firmware-sdk](https://github.com/WAGO/pfc-firmware-sdk) for more information.

## Prerequisites

Make sure that docker and make are installed on the host system.  
Tho install docker, please refer to the instructions depending on your host system, e.g for Ubuntu use [https://docs.docker.com/install/linux/docker-ce/ubuntu/](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

To install make, you can use apt:

    > sudo apt install make

## Build PFC firmware

The quickest way to create PFC firmware is to use the make wrapper:

    > make
    > ls ./build/images

**Note:** This will take some time.

## Using make wrapper

The make wrapper is used for convenience, to simplify the interaction with docker. There are some main goals defined:

-   **builder**: create docker image *pfc-builder*
-   **images**: ensure, that *pfc-builer* is available and copy images to *./build/images*
-   **run**: run *pfc-builder* in bash, so ptxdist can be configured and manually triggered
-   **clean**: cleanup everything

### Custom ptxdist configuration

By default, the full blown PFC image is created. To enable custom ptxdist configuration, the make goal *run* can be used. To avoid long running ptxdist build during creation of docker image, the flag `SKIP_BUILD_IMAGE` should be provided.

    > make run SKIP_BUILD_IMAGE=y

The image in run in bash mode with *ptxproj* as working directory, so you can
start using ptxdist.

    > ptxdist menuconfig
    > ptxdist go -q
    > ptxdist images -q

To save the results of the ptxdist build, you have to copy them to */backup* directory. Everything stored to */backup* becomes visible in .build/images directory of the host system.

**Note**: PTXdist configuration and build results will be removed when the container is closed. Make sure to store everything in */backup* directory before quitting bash.

## Using Dockerfile

Since the make wrapper is only used for convenience, everthing can also achieved by using docker directly.

### Create docker image

    > docker build --rm \
    --build-arg "USERID=`id -u`" \
    --build-arg "SKIP_BUILD_IMAGE=" \
    --file Dockerfile --tag pfc-builder .

When creating the docker image, the id of the user which will later run the image should be provided by build argument *USERID*. This ensures, that files transfered from container to host will have proper access rights.

The build argument *SKIP_BUILD_IMAGE* can be used to prevent creating pfc firmware images during docker build. Use this, when custom ptxdist configuration is needed.

### Run the image

    > docker run --rm -it --user "`id -u`" \
    -v "$(pwd):/backup" \
    pfc-builder bash

When running the image, the id of the current user should be provided to ensure that files transfered to host will have proper access rights.

To enable data transfer to host, a volume should be specified.

## License

The Dockerfile and the make wrapper are released to the public domain in terms of [the Unlicense](http://unlicense.org).

However, the resulting docker image is comprised of software using different licenses including GPL, MPL and others. Please use the docker image with respect to that.