#!/bin/bash
# json validator

export JSON_FILE="${1}"

#if json is not valid, program will be throw error.
jsonlint-php ${JSON_FILE}

# Check if commit message match with regex
if [[ $? -eq 0 ]]; then
    echo -e "\e[32mCommit message check success!\e[0m"
else
    echo -e "\e[31mPlease rename your branch.\e[0m";
    exit 1;
fi
 
