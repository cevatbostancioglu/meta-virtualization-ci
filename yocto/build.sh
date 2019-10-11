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
    if [ $ENV_OK -eq 1 ]; then
        echo -e "\e[1;32m\nNo problems found on build environment.\n\e[0m"
    else
        echo -e "\e[1;31m\nThere are problems with the build environment!\e[0m\n"
        exit 1
    fi
}

do_fetch ()
{
    echo "do_fetch start"

    do_env_check
    
    pushd ${DOWNLOAD_PATH}

    if [ ! -d poky ]; then
        git clone -b ${1} git://git.yoctoproject.org/poky
    fi

    if [ ! -d meta-openembedded ]; then
        git clone -b ${1} git://git.openembedded.org/meta-openembedded
    fi

    if [ ! -d meta-virtualization ]; then
        git clone -b master git://git.yoctoproject.org/meta-virtualization
    fi

    popd

    echo "do_fetch done"
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


    mkdir -p ${DOWNLOAD_PATH} || true
    mkdir -p ${SSTATE_DIR} || true
    mkdir -p ${TMPDIR} || true

    pushd ${DOWNLOAD_PATH}

    source ${POKY_DIR}/oe-init-build-env ${BUILD_DIR}
    
    cp ${YOCTO_DIR}/conf/bblayers.conf.example ${BUILD_DIR}/conf/bblayers.conf

    cp ${YOCTO_DIR}/conf/${TARGET_ARCH}/local.conf.example ${BUILD_DIR}/conf/local.conf

    cp ${YOCTO_DIR}/conf/${TARGET_ARCH}/local_conf_* ${BUILD_DIR}/conf/

    sed_command="${1}"
    sed -i "s/<git_branch>/$sed_command/g" "${BUILD_DIR}/conf/local.conf"
    sed -i "s/<MACHINE_NAME>/${MACHINE_NAME}/g" "${BUILD_DIR}/conf/local.conf"

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
    runqemu ${MACHINE_NAME}
}

###############################################################################
# MAIN
###############################################################################

# Present usage.
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

SHIFTCOUNT=0
TARGET_ARCH="arm"
MACHINE_NAME="qemux86"

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

shift $SHIFTCOUNT

# Process all commands.
while true ; do
    case "$1" in
        fetch)
            do_fetch $2
            shift
            break
            ;;
        wget)
            do_wget_meta "sumo" "meta-virtualization"
            shift
            break
            ;;
        runqemu)
            do_prep_host $2
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
            do_prep_host $2
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