#!/bin/bash
# json validator

export JSON_FILE="${1}"

#if json is not valid, program will be throw error.
jsonlint-php ${JSON_FILE}

# Check if json is valid
if [[ $? -eq 0 ]]; then
    echo -e "\e[32mJSON-Check success!\e[0m"
else
    echo -e "\e[31mJSON-Check failed for ${JSON_FILE}.\e[0m";
    exit 1;
fi
 
