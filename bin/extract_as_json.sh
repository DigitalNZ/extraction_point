#!/bin/bash

set -e

TYPE=$1
OUTPUT=$2
options=$3

command_root="docker-compose run requestor curl -H"
command="$command_root \"Accept: application/json\" -X GET \"http://app:4000/"

case $TYPE in
    meta) command=$command;;
    audio-recordings | documents | still-images | vidoes | web-links) command="$command$TYPE";;
    *) topic_stub="topics?topic_type=$TYPE"; command="$command$topic_stub";;
esac

if [[ -n "${options// /}" ]]; then
    echo "added $options to request"

    case $command in
        *\?*) options="&$options";;
        *) options="?$options";;
    esac

    command="$command$options\""
else
    command="$command\""
fi

if [[ -n "${OUTPUT// /}" ]]; then
    command="$command --output $OUTPUT"
else
    command="$command --output $TYPE.csv"
fi

echo $command

eval $command
