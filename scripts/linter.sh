#!/usr/bin/env bash

set -o errexit  # stop on first error
set -o xtrace  # log every step
set -o nounset  # exit when script tries to use undeclared variables


###############################################################################
# MAIN
###############################################################################

# Process all commands.
while true ; do
    case "$1" in
        commit-msg)
            source scripts/hooks/commit-msg.sh
            shift
            break
            ;;
        branch-name)
            source scripts/hooks/branch-name.sh
            shift
            break
            ;;
        json)
            source scripts/hooks/jsonlint.sh scripts/hooks/test.json
            shift
            break
            ;;
        *)
            if [[ -n $1 ]]; then
                echo "!!!!!!!!!!!Unknown build command " $1 "!!!!!!!!!!"
            fi
            exit 1
            shift
            break
            ;;
    esac
done