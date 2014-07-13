#!/bin/bash

# Where to store released packages.
RELEASE_PKGPATH="release"

# Will be appended to RM_BUILD_NAME. Can be left blank.
RELEASE_SUFFIX=""

# Will be appended to RM_BUILD_DATE. Should not be left blank, may be left unchanged.
RELEASE_DESCRIPTION="release build"

# Name of a rm-custom configuration to be made default. May be left blank.
# Note: only the config NAME has to be specified.
# Example: to make rm-custom/akari.cfg the default config, you have to specify "akari"
# Another note: changing this will also affect RELEASE_SUFFIX
RELEASE_DEFAULTCFG=""

# If 1, the release directory will be wiped out after package generation
RELEASE_CLEANUP=1

# This function will be called when the release is ready but hasn't been packaged yet,
# for you to customize the release here. May be left as-is.
#
# First argument: full path to the release directory

function prepackage
{
    echo    
}

# This function will be called after the release has been packaged. May be left as-is.
#
# First argument: full path to the release package

function postpackage
{
    echo
}

# NOTE: You can also overwrite any config.sh option here
# See EXAMPLE_config.sh for reference

