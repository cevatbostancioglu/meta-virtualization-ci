#!/usr/bin/env bash

set -o errexit  # stop on first error
set -o xtrace  # log every step
set -o nounset  # exit when script tries to use undeclared variables

echo "Syntax check started for $0. On any syntax error script will exit"
bash -n $0 # check and exit for syntax errors in script.
echo "Syntax is OK."

echo "running with ${USER}"

usage ()
{
    echo "usage"    
    exit 1
}

is_program_installed() {
    if ! [ -x "$(command -v $1)" ]; then
        echo -e "\e[1;31mRequirement "$1" is not installed!\e[0m"
        ENV_OK=0
    fi
}

do_env_check(){
    ENV_OK=1
    
    is_program_installed sed
    is_program_installed bats
    is_program_installed jsonlint-php

    if [ $ENV_OK -eq 1 ]; then
        echo -e "\e[1;32m\nNo problems found on build environment.\n\e[0m"
    else
        echo -e "\e[1;31m\nThere are problems with the build environment!\e[0m\n"
        exit 1
    fi
}

do_meta_fetch ()
{
    echo "do_meta_fetch start"

    do_env_check
    
    pushd ${DOWNLOAD_PATH}

    if [ ! -d poky ]; then
        git clone -b ${1} git://git.yoctoproject.org/poky
    else
        cd poky
        git checkout ${1}
        cd ..
    fi

    if [ ! -d meta-openembedded ]; then
        git clone -b ${1} git://git.openembedded.org/meta-openembedded
    else
        cd meta-openembedded
        git checkout ${1}
        cd ..
    fi

    if [ ! -d meta-bbb ]; then
        git clone -b ${1} https://github.com/jumpnow/meta-bbb.git
    else
        cd meta-bbb
        git checkout ${1}
        cd ..
    fi

    if [ ! -d meta-qt5 ]; then
        git clone -b ${1} https://github.com/meta-qt5/meta-qt5.git
    else
        cd meta-qt5
        git checkout ${1}
        cd ..
    fi

    if [ ! -d meta-security ]; then
        git clone -b ${1} git://git.yoctoproject.org/meta-security.git
    else
        cd meta-security
        git checkout ${1}
        cd ..
    fi

    if [ ! -d meta-jumpnow ]; then
        git clone -b ${1} https://github.com/jumpnow/meta-jumpnow.git
    else
        cd meta-jumpnow
        git checkout ${1}
        cd ..
    fi

    ## other layers are not working good/maintained.
    if [ ! -d meta-virtualization ]; then
        git clone -b master git://git.yoctoproject.org/meta-virtualization
    else
        cd meta-virtualization
        git checkout master
        cd ..
    fi

    popd

    echo "do_meta_fetch done"
}

do_bitbake_fetch ()
{
    echo "do_bitbake_fetch start"

    bitbake -c fetch ${IMAGE_NAME} 

    echo "do_bitbake_fetch done"
}

do_clean ()
{
    echo "do_clean start"

    rm -rf ${BUILD_DIR}

    echo "do_clean done"
}

do_prep_host ()
{
    echo "do_prep_host start"

    set +o nounset

    pushd ${DOWNLOAD_PATH}

    source ${POKY_DIR}/oe-init-build-env ${BUILD_DIR}
    
    cp ${YOCTO_DIR}/conf/bblayers.conf.example_${MACHINE_NAME} ${BUILD_DIR}/conf/bblayers.conf

    cp ${YOCTO_DIR}/conf/local.conf.example_${MACHINE_NAME} ${BUILD_DIR}/conf/local.conf

    cp ${YOCTO_DIR}/conf/${TARGET_ARCH}/local_conf_* ${BUILD_DIR}/conf/

    sed_command="${1}"
    sed -i "s|<git_branch>|$sed_command|g" "${BUILD_DIR}/conf/local.conf"
    sed -i "s|<MACHINE_NAME>|${MACHINE_NAME}|g" "${BUILD_DIR}/conf/local.conf"
    sed -i "s|<TARGET_ARCH>|${TARGET_ARCH}|g" "${BUILD_DIR}/conf/local.conf"
    sed -i "s|<CACHE_POLICY>|${CACHE_POLICY}|g" "${BUILD_DIR}/conf/local.conf"

    sed -i "s|<DL_DIR>|${DOWNLOAD_PATH}|g" "${BUILD_DIR}/conf/bblayers.conf"

    popd

    echo "do_prep_host done"
}

do_build ()
{
    echo "do_build start"

    bitbake ${IMAGE_NAME}

    echo "do_build done"
}

do_custom_build ()
{
    echo "do_custom_build start"

    bitbake ${1}

    echo "do_custom_build done"
}

do_runqemu ()
{
    echo "do_runqemu start"
    rm -rf ${QEMU_NAMED_OUT} || true

    #https://gitlab.com/gitlab-org/gitlab-runner/issues/2231
    #https://gitlab.com/gitlab-org/gitlab-runner/issues/3165
    setsid nohup runqemu ${MACHINE_NAME} nographic > ${QEMU_NAMED_OUT} &
    
    sleep 5

    result=$(ps -ax | grep "[s]cripts/runqemu" | wc -l)

    if [ "$result" -eq 0 ]; then
        echo "running QEMU:${MACHINE_NAME} failed."
        exit 1
    else
        echo "running QEMU:${MACHINE_NAME} success"
        exit 0
    fi

    echo "do_runqemu done"
}

do_take_release()
{
    echo "do_take_release start"

    pushd ${DEPLOY_DIR}
        rm -rf deploy.tar.gz || true
        #TODO: images folder takes lots of time to upload/download. just disable it for now.
        tar -cvzf deploy.tar.gz  licenses
    popd

    mv ${DEPLOY_DIR}/deploy.tar.gz ${PWD}/../

    echo "do_take_release done"
}

###############################################################################
# MAIN
###############################################################################

# Present usage.
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

if [ ! -d conf ]; then
    cd yocto
fi

SHIFTCOUNT=0
MACHINE_NAME=${MACHINE_NAME:-qemuarm}

source machine_configs/${MACHINE_NAME}

TARGET_ARCH=${TARGET_ARCH:-arm}
IMAGE_NAME=${IMAGE_NAME:-console-image}

while getopts ":h?:o:f:m:p:c:i:a:" opt; do
    case "${opt:-}" in
        h|\?)
            usage
            exit 0
            ;;
        a)
            export TARGET_ARCH=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        o)
            export BUILD_TYPE=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        f)
            export IMAGE_NAME=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        m)
            export MACHINE_NAME=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        p)
            export IMAGE_TYPE=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        c)
            export CUSTOM_RECIPE=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        i)
            export TARGET_ADDRESS=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
    esac
done

source ${PWD}/.config

mkdir -p ${DOWNLOAD_PATH} || true
mkdir -p ${BUILD_DIR} || true
mkdir -p ${SSTATE_DIR} || true
mkdir -p ${TMPDIR} || true
mkdir -p ${DEPLOY_DIR} || true

shift $SHIFTCOUNT

# Process all commands.
while true ; do
    case "$1" in
        meta-fetch)
            do_meta_fetch $2
            shift
            break
            ;;
        bitbake-fetch)
            do_prep_host ${2:-master}
            do_bitbake_fetch
            shift
            break
            ;;
        take-release)
            do_take_release
            shift
            break
            ;;
        wget)
            do_wget_meta "sumo" "meta-virtualization"
            shift
            break
            ;;
        runqemu)
            do_prep_host ${2:-master}
            do_runqemu
            shift
            break
            ;;
        clean)
            do_clean
            shift
            break
            ;;
        build)
            do_prep_host ${2:-master}
            do_build
            shift
            break
            ;;
        custom-build)
            do_prep_host $2
            do_custom_build ${3}
            shift
            break
            ;;
        *)
            if [[ -n $1 ]]; then
                echo "!!!!!!!!!!!Unknown build command " $1 "!!!!!!!!!!!!!"
                usage
            fi
            shift
            break
            ;;
    esac
done