#!/bin/bash
# Git hook created for reminding developers to add changed module name into their commits.

export MESSAGE="${CI_COMMIT_MESSAGE}"

# a-z, A-Z, 0-9, must have :
# example:"kvm: updated x,y,z modules."
export COMMIT_MATCH_REGEX='[a-zA-Z]*:'
 
# Check if commit message match with regex
if [[ $MESSAGE =~ $COMMIT_MATCH_REGEX ]]; then
    echo -e "\e[32mCommit message check success!\e[0m"
else
    echo -e "\e[31mPlease follow the commit message template \"<module>: <changes>\" and try commiting again.\e[0m";
    exit 1;
fi
 
