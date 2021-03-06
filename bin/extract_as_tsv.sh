#!/bin/bash

set -e

TYPE=$1
OUTPUT=$2
options=$3

command_root="docker-compose run requestor curl -H"
command="$command_root \"Accept: text/csv\" -X GET \"http://app:4000/"

case $TYPE in
    meta) meta_path="meta.csv"; command="$command$meta_path";;
    audio-recordings | documents | still-images | vidoes | web-links | users | relations) command="$command$TYPE.csv";;
    *) topic_stub="topics.csv?topic_type=$TYPE"; command="$command$topic_stub";;
esac

if [[ -n "${options// /}" ]]; then
    echo "added $options to request"

    case "${command: -3}" in
        csv) options="?$options";;
        *) options="&$options";;
    esac

    command="$command$options\""
else
    command="$command\""
fi

if [[ -n "${OUTPUT// /}" ]]; then
    command="$command --output $OUTPUT"
else
    command="$command --output $TYPE.tsv"
fi

echo $command

eval $command
