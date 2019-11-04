#!/bin/bash
# Git hook created for reminding developers they should start branch names with feature/hotfix/fix 

export MESSAGE="${CI_COMMIT_REF_NAME}"

#TODO expend name dict.
result=$(echo $MESSAGE | grep -e 'feature\|hotfix\|fix' | wc -l)

if [[ $result -eq 1 ]]; then
    echo -e "\e[32mBranch name success!\e[0m"
else
    echo -e "\e[31mPlease rename your branch.\e[0m";
    exit 1;
fi
 
