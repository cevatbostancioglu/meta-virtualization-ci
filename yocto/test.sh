#!/usr/bin/env bash

set -o errexit  # stop on first error
set -o xtrace  # log every step
set -o nounset  # exit when script tries to use undeclared variables

echo "Syntax check started for $0. On any syntax error script will exit"
bash -n $0 # check and exit for syntax errors in script.
echo "Syntax is OK."

usage ()
{
    echo "usage"
    exit 1
}

do_shutdown_qemu_resources ()
{
    echo "do_shutdown_qemu_resources start"

    ## if qemu is not open, script kill itself.
    result=$(ps -ax  | grep ${MACHINE_NAME} | grep -v $BASHPID | grep -v "test.sh") 
    $(echo $result | awk '{print $1}' | xargs kill)

    if [ $? -eq 0 ]; then
        echo "successfully killed qemu resources"
    else
        echo "qemu resource clean failed"
        exit 1
    fi

    exit ${1}

    echo "do_shutdown_qemu_resources done"
}

do_check_device_is_opening ()
{
    CURRENT_DATE=$( date +%s )
    END_DATE=$(( CURRENT_DATE+40 ))

    result=0

    if [ ! -f ${QEMU_NAMED_OUT} ]; then
        do_shutdown_qemu_resources $FAILED
    fi

    while [ $CURRENT_DATE -le $END_DATE ];
    do
        CURRENT_DATE=$( date +%s )
        result=$(cat ${QEMU_NAMED_OUT} | grep "login:" | wc -l)

        if [ "$result " -eq 1 ]; then
            break
        fi

        sleep 1
    done

    if [ ! "$result" -eq 1 ]; then
        do_shutdown_qemu_resources $FAILED
    fi
}

do_copy_file()
{
    echo "do_copy_file start"

    scp ${QEMU_SSH_OPTION} ${QEMU_MACHINE_USER}@${QEMU_MACHINE_IP}:${1} ${PWD}

    echo "do_copy_file done"
}

do_run_command()
{
    echo "do_run_command start"

    touch ${2} || true
    ssh ${QEMU_SSH_OPTION} ${QEMU_MACHINE_USER}@${QEMU_MACHINE_IP} "${1}" > ${2}

    echo "do_run_command done"
}

do_copy_logs()
{
    echo "do_copy_logs start"

    pushd test_result
        do_copy_file "/var/log/messages"
        do_run_command "dmesg" "dmesg"
        do_run_command "systemctl list-unit-files" "list-unit-files"
    popd

    echo "do_copy_logs done"
}

do_test_runqemu ()
{
    echo "do_test_runqemu start"

    do_check_device_is_opening

    rm -rf test_result
    mkdir -p test_result || true

    do_copy_logs

    touch test_result/bats_result.txt || true

    ## always continue
    test_result=$(bats ../scripts/tests/login.bats || true)
    echo "$test_result" > test_result/bats_result.txt

    test_result=$(echo $test_result | grep "not ok" | wc -l)

    rm -rf device_report.tar.gz || true
    tar -cvzf device_report.tar.gz test_result

    mv *.tar.gz ../

    if [ "$test_result" -eq 0 ]; then
        echo "ALL TESTS PASSED"
        do_shutdown_qemu_resources $SUCCESS
    else
        echo "${test_result} TESTS FAILED"
        do_shutdown_qemu_resources $FAILED
    fi

    echo "do_test_runqemu done"
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

FAILED=1
SUCCESS=0
SHIFTCOUNT=0

while getopts ":h?:a:m:" opt; do
    case "${opt:-}" in
        h|\?)
            usage
            exit 0
            ;;
        a)
            export TARGET_ARCH=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
        m)
            export MACHINE_NAME=$OPTARG
            SHIFTCOUNT=$(( $SHIFTCOUNT+2 ))
            ;;
    esac
done

source ${PWD}/.config

shift $SHIFTCOUNT

# Process all commands.
while true ; do
    case "$1" in
        runqemu)
            do_test_runqemu
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
