#!/bin/bash

if [ "x$1" != "x" ]; then
	TARGET="$1"
else
	cat <<EOF
Usage: $0 targetfile

Upgrades references to RM cvars to v1.7.0 format in targetfile, which may be either a single file or a directory, in which case all files withing that directory will be converted recursively.
EOF
	exit 1
fi

TARGET="$(readlink -f "$TARGET")"
BASEDIR="$(readlink -f "$0" | sed -e 's@/[^/]*$@@')"
RAND="$RANDOM"

if [ -d "$TARGET" ]; then
	echo " --- Entering $TARGET --- "
	ls "$TARGET" | grep -v '\.tmp$' | while read line; do
		$0 "$TARGET/$line"
	done
	exit 0
fi

echo "ALTERING: $TARGET"
"$BASEDIR"/cvars.sed "$TARGET" > "$TARGET.$RAND.tmp" && mv "$TARGET.$RAND.tmp" "$TARGET"
rm -fv "$TARGET.$RAND.tmp"
