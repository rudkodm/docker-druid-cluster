#!/usr/bin/env bash

function envsubst_file() {
    file=${1}
    if [ -f "$file" ]
    then
        echo "Environment variables in file ${file} will be substituted"

        env | while IFS='=' read -r name value; do
            sed_cmd='s|${'${name}'}|'${value}'|g'
            sed -i ${sed_cmd} ${file}
        done
    else
    echo "$file not found."
    fi
}

function envsubst_dir() {
    dir=${1}
    if [ -d "${dir}" ]
    then
        echo "Environment variables in directory ${dir} will be substituted"
        for f in $(find ${dir} -name '*.*'); do
            echo "+ ${f}"
            envsubst_file ${f}
        done
    else
    echo "${dir} not found."
    fi
}


envsubst_dir $1
