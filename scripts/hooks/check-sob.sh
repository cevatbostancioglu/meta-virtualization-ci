#!/bin/bash

#TODO
export MESSAGE="${1}"

do_check_duplicate_sob()
{
    # catches duplicate Signed-off-by lines.
    test "" = "$(grep '^Signed-off-by: ' "$MESSAGE" |
        sort | uniq -c | sed -e '/^[ 	]*1[ 	]/d')" || {
        echo -e "\e[31mDuplicate Signed-off-by lines.\e[31m"
        exit 1
    }
}

do_check_duplicate_sob
