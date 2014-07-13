#!/bin/bash

if [ -z $INCLUDE ]; then
    echo "This is not a script." >&2
    exit 1
fi

RMLIB_REQUIRED="rm mv cp mkdir cat grep:pcregrep sed git"

function error
{
    echo -e "\n$*" >&2
    exit 1
}

function getqcc
{
    local i=0
    local qcc=""

    echo "Looking for a QuakeC compiller" >&2

    while true; do
        qcc="${QCC[$i]}"

        [ x"$qcc" = x ] && error "Failed to find a QuakeC compiller"

        echo -n " -- Trying $qcc... " >&2
        which "$qcc" &>/dev/null && break

        echo -e "\e[31;1mmissing\e[0m" >&2
        let i++
    done

    echo -e "\e[32;1mfound\e[0m" >&2
    echo "$qcc"
}

function rconopen
{
    RCON_ADDRESS="$1"
    RCON_PORT="$2"
    RCON_PASSWORD="$3"
}

RCON_USE_NETCAT=0
function rconsend
{
    echo " --:> $1"
    
    if [ $RCON_USE_NETCAT != 0 ]; then
        printf "\377\377\377\377rcon %s %s" $RCON_PASSWORD "$1" | netcat -uc $RCON_ADDRESS $RCON_PORT
    else
        printf "\377\377\377\377rcon %s %s" $RCON_PASSWORD "$1" > /dev/udp/$RCON_ADDRESS/$RCON_PORT
    fi
}

function rconsendto
{
    echo " --:> $1"
    printf "\377\377\377\377rcon %s %s" "$3" "$4" > /dev/udp/"$1"/"$2"
}

function rm-version-checkformat
{
    perlgrep '^v\d+\.\d+\.\d+[a-zA-Z\d]*$'
}

function rm-version
{
    if ! git describe --tags &> /dev/null; then
        echo git
        return 0;
    fi
    
    (git describe --tags | while read line; do
        echo $line | rm-version-checkformat && exit # Note: this is a subshell exit
    done; echo git) | head -1
}

function rm-version-or
{
    local v="$(rm-version)"
    [ "$v" = "git" ] && v="$1"
    echo "$v"
}

function rm-hasversion
{
    [ "$(rm-version)" != "git" ]
}

function warning
{
    echo -e "***\n\e[31;1mWARNING: \e[0m$@\e[0m\n***\n"
    sleep 1 #little annoyance
}

function warn-oldconfig
{
    warning "your $1 is OUTDATED! It does not contain option '$2', using the default value of '$3'! Please refer to EXAMPLE_$1 and fix this!"
}

PERLGREP=""
function perlgrep
{
    if [ -z "$PERLGREP" ]; then
        if hascommand grep; then
            PERLGREP="grep -P"
        elif hascommand pcregrep; then
            PERLGREP="pcregrep"
        else
            error "No suitable grep command found"
        fi
    fi
    
    $PERLGREP "$@"
}

REQUIRED_FOUND=""
OPTIONAL_FOUND=""

function test-command
{
    if [ "$1" = "grep" ]; then
        echo a | grep -Pq a
    fi
}

function hasoptional
{
    for i in $OPTIONAL_FOUND; do
        [ $i == $1 ] && return 0;
    done; return 1
}

function hasrequired
{
    for i in $REQUIRED_FOUND; do
        [ $i == $1 ] && return 0;
    done; return 1
}

function hascommand
{
    for i in $REQUIRED_FOUND $OPTIONAL_FOUND; do
        [ $i == $1 ] && return 0;
    done; return 1
}

function require
{
    local req="$RMLIB_REQUIRED $*"
    local lacking=""

    echo "rmlib is checking for required utilities..."
    
    # TODO: maybe remove this completely and use python-dprcon to support secure rcon?
    if ! echo a > /dev/udp/localhost/1; then
        echo "WARNING: shell doesn't support /dev/udp! Will attempt to use netcat instead"
        req="$req netcat"
        RCON_USE_NETCAT=1
    fi

    for i in $req; do
        local all="$i"
        local i="${all%%:*}"
        local alts="${all##$i:}"

        echo -n " - ${i##%}... "

        if [ ${i##%} = $i ]; then          # no %prefix, required
            if which $i &> /dev/null; then
                if test-command $i; then
                    echo -e '\e[32;1mfound\e[0m'
                    REQUIRED_FOUND="$REQUIRED_FOUND $i"
                    continue
                else
                    echo -en "\e[31;1mfound, but incompatible!\e[0m"
                fi
            else
                echo -en '\e[31;1mnot found!\e[0m'
            fi
            
            local altfound=false
            if [ "$i" != "$alts" ]; then
                echo " Will look for alternatives..."

                for alt in $(echo $alts | sed -e 's/:/ /g'); do
                    echo -n "     - ${alt}... "
                    if which $alt &> /dev/null; then
                        if test-command $alt; then
                            echo -e '\e[32;1mfound\e[0m'
                            altfound=true
                            REQUIRED_FOUND="$REQUIRED_FOUND $alt"
                            break
                        else
                            echo -e '\e[31;1mfound, but incompatible!\e[0m'
                        fi
                    else
                        echo -e '\e[31;1mnot found!\e[0m'
                    fi
                done 
            else
                echo
            fi

            $altfound || lacking="$lacking $i"
        else                                # %prefix, optional
            i="${i##%}"
            
            if which $i &> /dev/null; then
                if test-command $i; then
                    echo -e '\e[32;1mfound\e[0m'
                    OPTIONAL_FOUND="$OPTIONAL_FOUND $i"
                else
                    echo -e '\e[33;1mincompatible but optional\e[0m'
                fi
            else
                echo -e '\e[33;1mnot found but optional\e[0m'
            fi
        fi
    done
    
    if [ -n "$lacking" ]; then
        error "The following utilities are required but are not present or are incompatible: $lacking. Please install them to proceed."
    fi
    
    echo "All OK, proceeding"
}

git symbolic-ref HEAD &> /dev/null || error "Can't proceed: not a git repository."

