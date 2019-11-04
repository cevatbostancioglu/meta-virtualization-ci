#!/bin/bash

#TODO
export MESSAGE="${1}"

do_check_rob()
{
    test "" = "$(grep '^Reviewed-bby: ' "$MESSAGE")" || {
        echo -e "\e[31mPlease add your reviewer name into commit message.\e[31m"
        exit 1
    }
}

do_check_rob
