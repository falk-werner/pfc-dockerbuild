ARG REGISTRY_PREFIX=''
ARG CODENAME=xenial

FROM ${REGISTRY_PREFIX}ubuntu:${CODENAME}

RUN set -x \
    && apt update \
    && apt upgrade -y \
    && apt install -y --no-install-recommends \
        build-essential \
        curl \
        libncurses5-dev \
        wget \
        gawk \
        flex \
        bison \
        texinfo \
        python-dev \
        g++ \
        dialog \
        lzop \
        autoconf \
        libtool \
        xmlstarlet \
        xsltproc \
        doxygen \
        autopoint \
        gettext \
        rsync \
        vim \
        git \
        software-properties-common \
        bc \
        groff \
        zip

RUN set -x \
  && add-apt-repository ppa:git-core/ppa \
  && add-apt-repository ppa:git-core \
  && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash

RUN set -x \
  && apt install -y --no-install-recommends \
    git-lfs \
  && git lfs install

ARG BUILD_DIR=/tmp/build

ARG DUMB_INIT_VERSION=1.2.2
RUN set -x \
  && mkdir -p "${BUILD_DIR}" \
  && cd "${BUILD_DIR}" \
  && curl -fSL -s -o dumb-init-${DUMB_INIT_VERSION}.tar.gz https://github.com/Yelp/dumb-init/archive/v${DUMB_INIT_VERSION}.tar.gz \
  && tar -xf dumb-init-${DUMB_INIT_VERSION}.tar.gz \
  && cd "dumb-init-${DUMB_INIT_VERSION}" \
  && make \
  && chmod +x dumb-init \
  && mv dumb-init /usr/local/bin/dumb-init \
  && dumb-init --version \
  && cd \
  && rm -rf "${BUILD_DIR}"

ARG TOOLCHAIN_DIR=/opt/LINARO.Toolchain-2017.10
ARG TOOLCHAIN_REPO=http://www.github.com/wago/gcc-linaro.toolchain-2017-precompiled.git
ARG TOOLCHAIN_BRANCH=master
RUN set -x \
  && mkdir -p "${TOOLCHAIN_DIR}" \
  && git clone --depth=1 --branch="${TOOLCHAIN_BRANCH}" --single-branch "${TOOLCHAIN_REPO}" "${TOOLCHAIN_DIR}" 

ARG PTXDIST_REPO=http://github.com/wago/ptxdist.git
ARG PTXDIST_BRANCH=master
RUN set -x \
  && mkdir -p "${BUILD_DIR}" \
  && cd "${BUILD_DIR}" \
  && git clone --depth=1 --branch="${PTXDIST_BRANCH}" --single-branch "${PTXDIST_REPO}" "${BUILD_DIR}" \
  && ./configure \
  && make \
  && make install \
  && cd \
  && rm -rf "${BUILD_DIR}"

ARG USERID=1000
RUN set -x \
    && useradd -u "$USERID" -ms /bin/bash user

ARG PTXPROJ_DIR=/home/user/ptxproj
ARG SDK_REPO=https://github.com/WAGO/pfc-firmware-sdk.git
ARG SDK_BRANCH=master
RUN set -x \
  && mkdir -p "${PTXPROJ_DIR}" \
  && cd "${PTXPROJ_DIR}" \
  && git clone --depth=1 --branch="${SDK_BRANCH}" --single-branch  "${SDK_REPO}" . \
  && chown -R user:user "${PTXPROJ_DIR}"

RUN set -x \
  && su - user -c "cd \"${PTXPROJ_DIR}\" && ptxdist select configs/wago-pfcXXX/ptxconfig_generic" \
  && su - user -c "cd \"${PTXPROJ_DIR}\" && ptxdist platform configs/wago-pfcXXX/platformconfig" \
  && su - user -c "cd \"${PTXPROJ_DIR}\" && ptxdist toolchain /opt/LINARO.Toolchain-2017.10/arm-linux-gnueabihf/bin/"

ARG SKIP_BUILD_IMAGE
RUN if [ "_${SKIP_BUILD_IMAGE}" = "_" ] ; then \
    set -x \
      && su - user -c "cd \"${PTXPROJ_DIR}\" && ptxdist go -q --j-intern=`nproc`" \
      && su - user -c "cd \"${PTXPROJ_DIR}\" && ptxdist images -q --j-intern=`nproc`" \
      && su - user -c "cd \"${PTXPROJ_DIR}\" && make wup" \
    ; fi

WORKDIR "${PTXPROJ_DIR}"

ENTRYPOINT ["dumb-init", "--"]
