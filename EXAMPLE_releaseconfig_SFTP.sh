#!/bin/bash

# Where to store released packages.
RELEASE_PKGPATH="release"

# Will be appended to RM_BUILD_NAME. Can be left blank.
RELEASE_SUFFIX=""

# Will be appended to RM_BUILD_DATE. Should not be left blank, may be left unchanged.
RELEASE_DESCRIPTION="git build" # This is not really a release, so we say "git build" here

# Name of a rm-custom configuration to be made default. May be left blank.
# Note: only the config NAME has to be specified.
# Example: to make rm-custom/akari.cfg the default config, you have to specify "akari"
# Another note: changing this will also affect RELEASE_SUFFIX
RELEASE_DEFAULTCFG=""

# If 1, the release directory will be wiped out after package generation
RELEASE_CLEANUP=1

#
#   These are custom options, and are used by the prepackage function
#

# SFTP settings are used to automatically transfer relevant files to the server.
SFTP_HOST=sftp.example.com
SFTP_PORT=22
SFTP_USER=whoever_has_access_to_nexuiz_data
SFTP_NEXDATA="where_nexuiz_data_is" # NOTE: this is the "~/.nexuiz/data/" directory, HOWEVER, NEVER use the ~/ shortcut here! SFTP will NOT expand it. Specify the FULL path.

# RCON settings are used to automatically reload RM config and restart the map
RCON_ADDRESS="nexuiz.example.com"
RCON_PORT=26000
RCON_PASSWORD="hackme"

RCON_COMMANDS=(
    "say ^2The map will be restarted in 3 seconds due to a mod upgrade!"
    "exec rm-custom/ufb.cfg"
    "defer 3 restart"
)

# This function will be called when the release is ready but hasn't been packaged yet,
# for you to customize the release here. May be left as-is.
#
# First argument: full path to the release directory

function prepackage
{
    sftp -P $SFTP_PORT $SFTP_USER@$SFTP_HOST <<EOF
cd $SFTP_NEXDATA
$(find "$1" -type d | while read line; do
    [ "$1" = "$line" ] && continue
    echo "mkdir ${line##$1/}"
done)
$(find "$1" -type f | while read line; do
    echo "put $line ${line##$1/}"
done)
quit
EOF

    local i=0
    while true; do
        local cmd="${RCON_COMMANDS[$((i++))]}"
        [ x"$cmd" = x ] && break
        rconsend "$cmd"
    done

    # Since we're going to cause a "failure", we will clean up here.
    [ $RELEASE_CLEANUP -eq 1 ] && rm -vrf "$1"

    cat << EOF
************************************************

    It's going to say "prepackage failed" now
    This is a terrible lie. It succeeded.

************************************************
EOF

    return 1
}

# This function will be called after the release has been packaged. May be left as-is.
#
# First argument: full path to the release package

# Akari's note: this will never be called in our case, since we throw an error in prepackage
function postpackage
{
    echo
}

# NOTE: You can also overwrite any config.sh option here
# See EXAMPLE_config.sh for reference

