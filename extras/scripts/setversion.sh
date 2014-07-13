#!/bin/bash


INCLUDE=1
. "$(dirname "$0")"/rmlib.sh || exit 1

if [ -z "$1" ]; then
    echo "Usage: $0 newversion" >&2
    echo "       $0 clear"      >&2
    exit 1;
fi

if [ "$1" = "clear" ]; then
    rm-hasversion || error "Not tagged with a version, nothing to clear"
    git tag -d "$(rm-version)" || error "git tag failed"
else
    echo "$1" | rm-version-checkformat || error "Invalid version format"
    rm-hasversion && error "Already tagged with version $(rm-version)"
    git tag "$1" || error "git tag failed"
fi


