#!/bin/bash

INCLUDE=1
. rmlib.sh || exit 1
require md5sum tar 7za:zip %convert

RELEASE=0
BUILD_DATE="$(date +"%F %T %Z")"
BUILD_DATE_PLAIN="$(date +%y%m%d%H%M%S)"
BRANCH="`git symbolic-ref HEAD 2>/dev/null | sed -e 's@^refs/heads/@@'`"
VERSION="$(rm-version)"
BUILT_PACKAGES=""
BUILT_PKGINFOS=""
BUILT_PKGNAMES=""
COMMONSUM=""
MENUSUM=""

function getfiledircache
{
    filecache=()
    dircache=()

    checkdir "${1}/"
    pushd "${1}/"

    if [ "${2}" = "reverse" ]; then
        readarray -t filecache < <(find ./ -type f | awk '{ print length, $0 }' | sort -rn | cut -d" " -f2-)
        readarray -t dircache  < <(find ./ -type d | awk '{ print length, $0 }' | sort -rn | cut -d" " -f2-)
    else
        readarray -t filecache < <(find ./ -type f | awk '{ print length, $0 }' | sort -n | cut -d" " -f2-)
        readarray -t dircache  < <(find ./ -type d | awk '{ print length, $0 }' | sort -n | cut -d" " -f2-)
    fi

    popd
}

function removeoldfiles
{
    if [ -n "${LINKDIRS}" ]; then

        getfiledircache "${BUILDDIR}" reverse

        for j in "${LINKDIRS[@]}"; do
            echo "  -- Removing old files and directories in '${j}/'.."
            checkdir "${j}"

            for i in "${filecache[@]}"; do
                rm "${j}/${i:2}" &>/dev/null
                rm "${BUILDDIR}/${i:2}"
            done

            for i in "${dircache[@]}"; do
                rmdir "${j}/${i:2}/" &>/dev/null
                rmdir "${BUILDDIR}/${i:2}/"
            done
        done
    fi

}

function linkfiles
{
    if [ -n "${LINKDIRS}" ]; then

        # Not tested under Windows at all
        export CYGWIN="winsymlinks:native"

        getfiledircache "${BUILDDIR}"

        for j in "${LINKDIRS[@]}"; do
            echo "  -- Linking files and directories in '${BUILDDIR}/' to '${j}/'"
            checkdir "${j}/"

            for i in "${dircache[@]}"; do
                mkdir "${j}/${i:2}/"
            done

            for i in "${filecache[@]}"; do
                ln --symbolic --force "${BUILDDIR}/${i:2}" "${j}/${i:2}"
            done

        done
    fi
}

function checkdir
{
    local dir="$(readlink -f "${1}")"
    if [[ -d "${dir}" ]]; then
        if [[ -x "${dir}" && -w "${dir}" ]]; then
            return 0
        else
            error "\"${dir}/\" has wrong permissions."
        fi
    else
        echo " -- Creating \"${dir}/\".."
        mkdir -p "${dir}/" || error "Could not create directory \"${dir}/\" in \"${dir%/*}/\"."
    fi
}

function buildall
{
    # $1 = suffix
    # $2 = desc
    
    USEQCC="$(getqcc)"
    [ -z "$USEQCC" ] && error "Couldn't get a QC compiller"

    echo " -- Calculating sum of menu/..."
    MENUSUM="$(find "$QCSOURCE/menu" -type f | grep -v "fteqcc.log" | xargs md5sum | md5sum | sed -e 's/ .*//g')"

	echo " -- Calculating sum of common/..."
	COMMONSUM="$(find "$QCSOURCE/common" -type f | grep -v "fteqcc.log" | grep -v "rm_auto.qh" | xargs md5sum | md5sum | sed -e 's/ .*//g')"
	MENUSUM="$MENUSUM$COMMONSUM"

    echo "#define RM_BUILD_DATE \"$BUILD_DATE ($2)\"" >  "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_NAME \"RocketMinsta$1\""   >> "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_VERSION \"$VERSION\""      >> "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_MENUSUM \"$MENUSUM\""      >> "$QCSOURCE"/common/rm_auto.qh
    echo "#define RM_BUILD_SUFFIX \"${1##-}\""        >> "$QCSOURCE"/common/rm_auto.qh
    
	echo "#define RM_SUPPORT_CLIENTPKGS"              >> "$QCSOURCE"/common/rm_auto.qh
	for i in $BUILT_PKGNAMES; do
		echo "#define RM_SUPPORT_PKG_$i"              >> "$QCSOURCE"/common/rm_auto.qh
	done

    buildqc server/
    mv -v progs.dat "$SVPROGS"

    buildqc client/
    mv -v csprogs.dat "$CSPROGS"

    buildqc menu/
    mv -v menu.dat "menu.pk3dir/menu.dat"
    makedata menu "$1" "$2"
    rm -v "menu.pk3dir"/*.dat

    rm -v "$QCSOURCE"/common/rm_auto.qh
}

function tocompress
{
	cat compressdirs | while read line; do find "$line" -name "*.tga" -maxdepth 1; done
}

function compress-gfx
{
	[ $COMPRESSGFX = 0 ] && return
	
	echo "   -- Compressing graphics"
	
	COMPRESSGFX_ABORT=0
	
	if [ ! -e compressdirs ]; then
		echo "Package didn't provide a list of directories to compress"
		COMPRESSGFX_ABORT=1
		return 0
	fi
	
	COMPRESSGFX_TEMPDIR="$(mktemp -d)"
	echo "     - Temporary directory with original graphics to be compressed: $COMPRESSGFX_TEMPDIR"
	
	if [ ! -e $COMPRESSGFX_TEMPDIR ]; then
		warning "Failed to create temporary directory! Skipping this package"
		COMPRESSGFX_ABORT=1
		return 1
	fi
	
	tocompress | while read line; do
		dir="$(echo $line | sed -e 's@/[^/]*.tga@@')"
		file="$(echo $line | sed -e 's@.*/@@')"
	
		mkdir -pv $COMPRESSGFX_TEMPDIR/$dir
	
		echo "Compressing: $line"
		
		if ! convert "$line" -quality $COMPRESSGFX_QUALITY "${line%%.tga}.jpg"; then
			warning "Failed to compress $line! Restoring the uncompressed file"
		fi
		
		mv -v "$line" $COMPRESSGFX_TEMPDIR/$dir
	done
}

function compress-restore
{
	[ $COMPRESSGFX = 0 ] && return
	[ $COMPRESSGFX_ABORT = 1 ] && return
	
	echo "   -- Cleaning up after compression"
	
	pkgdir="$PWD"
	pushd "$COMPRESSGFX_TEMPDIR"
	
	find -type f | sed -e 's@^./@@' | while read line; do
		mv -v "$line" "$pkgdir/$line"
		rm -vf "$pkgdir/${line%%.tga}.jpg"
	done
	
	popd
	
	rm -rf "$COMPRESSGFX_TEMPDIR"
}

function rmpack
{
    if hascommand 7za; then
        7za a -tzip -mfb258 -mpass15 "$@"
    elif hascommand zip; then
        echo zip -r "$@"
        zip -r "$@"
    else
        error "No usable archiver, WTF?"
    fi
}

function makedata
{
    local rmdata="$1"
    local suffix="$2"
    local desc="$3"

    echo " -- Building client-side package $1"
    
    pushd "$rmdata.pk3dir"
    rmdata="zzz-rm-$rmdata"
    
    local sum=""
    if [ "$rmdata" != "zzz-rm-menu" ]; then
        echo "   -- Calculating md5 sums"
        find -regex "^\./[^_].*" -type f -exec md5sum '{}' \; > _md5sums
        sum="$(md5sum "_md5sums" | sed -e 's/ .*//g')"
    else
        sum="$MENUSUM"
    fi
    
    if [ $CACHEPKGS = 1 ] && [ -e "${CACHEDIR}/$rmdata-$sum.pk3" ]; then
        echo "   -- A cached package with the same sum already exists, using it"
        
        popd
        cp -v "${CACHEDIR}/$rmdata-$sum.pk3" "${BUILDDIR}/$rmdata-$sum.pk3"
        echo "   -- Done"

        BUILT_PACKAGES="${BUILT_PACKAGES}$rmdata-$sum.pk3 "
        BUILT_PKGINFOS="${BUILT_PKGINFOS}_pkginfo_$sum.txt "
        BUILT_PKGNAMES="${BUILT_PKGNAMES}$1 "

        return
    fi
    
    compress-gfx
    
    echo "   -- Writing version info"
    echo "RocketMinsta$2 $VERSION client-side package ($3)" >  _pkginfo_$sum.txt
    echo "Built at $BUILD_DATE"                             >> _pkginfo_$sum.txt
    
    echo "   -- Compressing package"
    if ! rmpack "/tmp/$rmdata-${BUILD_DATE_PLAIN}_tmp.zip" *; then
        compress-restore
        error "Failed to package $rmdata"
    fi
    echo "   -- Removing temporary files"
    rm -vf _*
    
    compress-restore
    popd
        
    echo "   -- Installing to ${BUILDDIR}/"
    mv -v "/tmp/$rmdata-${BUILD_DATE_PLAIN}_tmp.zip" "${BUILDDIR}/$rmdata-$sum.pk3"

    if [ $CACHEPKGS = 1 ]; then
        echo "   -- Copying the package to cache"
        cp -v "${BUILDDIR}/$rmdata-$sum.pk3" "${CACHEDIR}/"
    fi

    echo "   -- Done"
    BUILT_PACKAGES="${BUILT_PACKAGES}$rmdata-$sum.pk3 "
    BUILT_PKGINFOS="${BUILT_PKGINFOS}_pkginfo_$sum.txt "
    BUILT_PKGNAMES="${BUILT_PKGNAMES}$1 "
}

function buildqc
{
    qcdir="$QCSOURCE/$1"

    # this is ugly, needs fixing
    if [ "$1" = "server/" ]; then
        progname="progs"
    elif [ "$1" = "client/" ]; then
        progname="csprogs"
    elif [ "$1" = "menu/" ]; then
        progname="menu"
    else
        error "$1 is unknown"
    fi

    local sum=""
    if [ $CACHEQC != 0 ]; then
        echo " -- Calculating sum of $1..."
        sum="$(find "$qcdir" -type f | grep -v "fteqcc.log" | xargs md5sum | md5sum | sed -e 's/ .*//g')"
        
        if [ "$progname" = "csprogs" ]; then # CSQC needs to know sum of menu
            sum="$sum.$MENUSUM"
        fi
        
        if [ -e "${CACHEDIR}/qccache/$progname.dat.$sum.$COMMONSUM" ]; then
            echo " -- Found a cached build of $1, using it"
            
            cp -v "${CACHEDIR}/qccache/$progname.dat.$sum.$COMMONSUM" "$progname.dat" || error "Failed to copy progs??"
            return
        fi
    fi

    echo " -- Building $qcdir"
    local olddir="$PWD"
    pushd "$qcdir" &>/dev/null || error "Build target does not exist? huh"
    $USEQCC $QCCFLAGS || error "Failed to build $qcdir"
    
    local compiled="$(cat progs.src | sed -e 's@//.*@@g' | sed -e '/^$/d' | head -1 | sed -e 's/[ \t]*$//')"
    local cname="$(echo "$compiled" | sed -e 's@.*/@@g')"
    if [ "$(readlink -f "$compiled")" != "$(readlink -f "$olddir/$cname")" ]; then
        cp -v "$compiled" "$olddir" || error "Failed to copy progs??"
    fi
    popd &>/dev/null
    
    if [ $CACHEQC != 0 ]; then
        echo " -- Copying compilled progs to cache"
        
        [ ! -e "${CACHEDIR}/qccache" ] && mkdir -p "${CACHEDIR}/qccache"
        cp -v "$progname.dat" "${CACHEDIR}/qccache/$progname.dat.$sum.$COMMONSUM" || error "WTF"
    fi
}

function is-included
{
    # special rule: menu package gets built after menu QC
    if [ $1 = "menu" ]; then
        return 1;
    fi
    
    if [ $1 = ${1##o_} ] && [ $1 = ${1##c_} ]; then
        # Not a prefixed package, checking if ignored
        for i in $IGNOREPKG; do
            [ $i = $1 ] && return 1;
        done

        return 0;
    fi

    for i in $BUILDPKG_OPTIONAL; do
        [ $i = ${1##o_} ] && return 0;
    done

    for i in $BUILDPKG_CUSTOM; do
        [ $i = ${1##c_} ] && return 0;
    done

    return 1
}

function makedata-all
{
    local suffix="$1"
    local desc="$2"
    
    #ls | grep -P "\.pk3dir/?$" | while read line; do   #damn subshells
    for line in $(ls | perlgrep "\.pk3dir/?$"); do
        is-included "$(echo $line | sed -e 's@\.pk3dir/*$@@g')" || continue
        makedata "$(echo $line | sed -e 's@\.pk3dir/*$@@g')" "$suffix" "$desc"
    done
}

function listcustom
{
    find "${BUILDDIR}/rm-custom" -maxdepth 1 -name "*.cfg" | while read cfg; do
        scfg="${cfg##*/}"
        echo -e "\t\t$scfg -- $(head -1 "$cfg" | sed -e 's@//cfgname:@@')"
    done
}

function finalize-install
{
    cp -v "rocketminsta.cfg" "${BUILDDIR}/"
    cp -v "rocketminsta-gameplay.cfg" "${BUILDDIR}/"
    cp -v "rocketminsta-compat.cfg" "${BUILDDIR}/"

    cat <<EOF >>"${BUILDDIR}/rocketminsta.cfg"
rm_clearpkgs
$(for i in $BUILT_PKGINFOS; do
    echo "rm_putpackage $i"
done)
EOF

    cat <<EOF >>"${BUILDDIR}/rocketminsta.cfg"

// Tells the engine to load the mod
set sv_progs $(echo "$SVPROGS" | sed -e 's@.*/@@g')
set csqc_progname $(echo "$CSPROGS" | sed -e 's@.*/@@g')
EOF

    if [ $RELEASE_RMCUSTOM -eq 1 ]; then
        mkdir -pv "${BUILDDIR}/rm-custom"
        cp -rv rm-custom/* "${BUILDDIR}/rm-custom"
    fi

    linkfiles
}

function configtest
{
	if [ -n "$SUPPORT_CLIENTPKGS" ] && [ "$SUPPORT_CLIENTPKGS" == 0 ]; then
		error "You have SUPPORT_CLIENTPKGS disabled, but this option is no longer supported. Please find a way to let your clients download the zzz-rm packages and remove this option from your config."
	fi
	
	SUPPORT_CLIENTPKGS=1
	
	if [ "$COMPRESSGFX" != 0 ] && ! hasoptional convert; then
		warning "You have COMPRESSGFX on without ImageMagick installed. Compression will be DISABLED."
		COMPRESSGFX=0
	fi
}

################################################################################

[ -e "config.sh" ] || error "No configuration file found. Please run \`cp EXAMPLE_config.sh config.sh', edit config.sh and try again."
. "config.sh" || error "Failed to read configuration"

if [ -z $BUILDPKG_OPTIONAL ]; then
    warn-oldconfig "config.sh" "BUILDPKG_OPTIONAL" "(-)"
    BUILDPKG_OPTIONAL=(-)
fi

if [ -z $BUILDPKG_CUSTOM ]; then
    warn-oldconfig "config.sh" "BUILDPKG_CUSTOM" "(-)"
    BUILDPKG_CUSTOM=(-)
fi

if [ -z $IGNOREPKG ]; then
    warn-oldconfig "config.sh" "IGNOREPKG" "(-)"
    IGNOREPKG=(-)
fi

if [ -z $CACHEPKGS ]; then
    warn-oldconfig "config.sh" "CACHEPKGS" "0"
    CACHEPKGS=0
fi

if [ -z $CACHEQC ]; then
    warn-oldconfig "config.sh" "CACHEQC" "0"
    CACHEQC=0
fi

if [ -z $COMPRESSGFX ]; then
    warn-oldconfig "config.sh" "COMPRESSGFX" "1"
    COMPRESSGFX=1
fi

if [ -z $COMPRESSGFX_QUALITY ]; then
    warn-oldconfig "config.sh" "COMPRESSGFX_QUALITY" "85"
    COMPRESSGFX_QUALITY=85
fi

if [ -z ${BUILDDIR} ]; then
    warn-oldconfig "config.sh" "BUILDDIR" "build"
    BUILDDIR="build"
fi

if ! [ "${LINKDIRS+test}" = "test" ]; then
    warn-oldconfig "config.sh" "LINKDIRS" "NEXDATA' or '$HOME/.nexuiz/data"
    LINKDIRS=("${NEXDATA:-${HOME}/.nexuiz/data}")
fi

if [ -n "$BUILDNAME" ]; then
    BRANCH=$BUILDNAME
fi

CACHEDIR="$(readlink -f "${CACHEDIR}/")"
BUILDDIR="$(readlink -f "${BUILDDIR}/")"

if [ "$1" = "cleancache" ]; then
    echo " -- Cleaning package cache"
    rm -vf "${CACHEDIR}/"*.pk3 "${CACHEDIR}/qccache/"*.dat.* || error "rm failed"
    exit
fi

configtest

removeoldfiles

if [ "$1" = "release" ]; then
    RELEASE=1
    
    if [ -n "$2" ]; then
        RELCFG="_$2"
    fi
    
    [ -e "releaseconfig$RELCFG.sh" ] || error "No release configuration file found. Please run \`cp EXAMPLE_releaseconfig.sh releaseconfig$RELCFG.sh', edit releaseconfig$RELCFG.sh and try again."
    . "releaseconfig$RELCFG.sh" || error "Failed to read release configuration"
    
    configtest
    
    [ -n "$RELEASE_SUFFIX"     ] && RELEASE_REALSUFFIX="-$RELEASE_SUFFIX"
    [ z"$BRANCH" = z"master"   ] || RELEASE_REALSUFFIX="-$BRANCH$RELEASE_REALSUFFIX"
    
    if [ -n "$RELEASE_DEFAULTCFG" ]; then
        if [ -n "$RELEASE_REALSUFFIX" ]; then
            RELEASE_REALSUFFIX="${RELEASE_REALSUFFIX}_cfg$RELEASE_DEFAULTCFG"
        else
            RELEASE_REALSUFFIX="-cfg$RELEASE_DEFAULTCFG"
        fi
        
        [ -e "rm-custom/$RELEASE_DEFAULTCFG.cfg" ] || error "Default configuration '$RELEASE_DEFAULTCFG.cfg' does not exist in rm-custom"
    fi
    
    PKGNAME="RocketMinsta${RELEASE_REALSUFFIX}"
    
    if rm-hasversion; then
        RELEASE_PKGNAME="${PKGNAME}_$VERSION"
    else
        RELEASE_PKGNAME="${PKGNAME}_$BUILD_DATE_PLAIN"
    fi
    
    RELEASE_PKGPATH="$(readlink -f "$RELEASE_PKGPATH")"
    mkdir "$RELEASE_PKGPATH/$RELEASE_PKGNAME" || error "Failed to create package directory"

    BUILDDIR="$(readlink -f "$RELEASE_PKGPATH/$RELEASE_PKGNAME")"
    SVPROGS="${BUILDDIR}/$(echo "$SVPROGS" | sed -e 's@.*/@@g')"
    CSPROGS="${BUILDDIR}/$(echo "$CSPROGS" | sed -e 's@.*/@@g')"

    checkdir "${BUILDDIR}/"
    makedata-all "$RELEASE_REALSUFFIX" "$RELEASE_DESCRIPTION"
    buildall "$RELEASE_REALSUFFIX" "$RELEASE_DESCRIPTION"
    finalize-install    

    if [ -n "$RELEASE_DEFAULTCFG" ]; then
        cat "rm-custom/$RELEASE_DEFAULTCFG.cfg" >> "${BUILDDIR}/rocketminsta-gameplay.cfg"
        sed -i '/exec "$rm_gameplay_config"/d' "${BUILDDIR}/rocketminsta-gameplay.cfg" # Without this, a recursive include will occur
    fi
    
    cp -v CHANGELOG "${BUILDDIR}/CHANGELOG.rmrelease"
    cp -v COPYING "${BUILDDIR}/COPYING.rmrelease"
    cat <<EOF > "${BUILDDIR}/README.rmrelease"

This is an auto generated $PKGNAME $VERSION release package, built at $BUILD_DATE. Installation:
    
    1) Extract the contents of this package into your Nexuiz data directory (typically ~/.nexuiz/data/)
    2) Edit your server config and add the following line at very top:
        
        exec rocketminsta.cfg
EOF

    if [ $RELEASE_RMCUSTOM -eq 1 ]; then
        cat <<EOF >> "${BUILDDIR}/README.rmrelease"
        
        If you'd like to use one of the custom configurations,
        add the following at the bottom of your config:
        
            rmcustom NAME_OF_CUSTOM_CONFIG.cfg
        
        The following configurations were included at build time: `ls rm-custom/*.cfg | while read line; do line=${line##rm-custom/}; echo -n "$line "; done`
EOF
    fi

    cat <<EOF >> "${BUILDDIR}/README.rmrelease"
    3) MAKE SURE that the following packages can be autodownloaded by clients:
        $BUILT_PACKAGES
        
        This package contains all of them
    4) Start the server and enjoy.
EOF

    cat <<EOF >> "${BUILDDIR}/README.rmrelease"

RocketMinsta project: http://rocketminsta.net/

EOF

    prepackage "$RELEASE_PKGPATH/$RELEASE_PKGNAME" || error "prepackage failed"

    pushd "${BUILDDIR}/" &>/dev/null
    tar -zcvf "$RELEASE_PKGPATH/$RELEASE_PKGNAME.tar.gz" * | while read line; do
        echo "Adding file: $line"
    done
    popd &>/dev/null

    if [ $RELEASE_CLEANUP -eq 1 ]; then
        rm -vrf "$RELEASE_PKGPATH/$RELEASE_PKGNAME"
    fi

    postpackage "$RELEASE_PKGPATH/$RELEASE_PKGNAME.tar.gz" || error "postpackage failed"

    cat <<EOF
**************************************************

    Finished $PKGNAME release
    
    Package path:
        $RELEASE_PKGPATH/$RELEASE_PKGNAME.tar.gz

**************************************************
EOF

    exit
fi

RELEASE_RMCUSTOM=1
PREFIX="-$BRANCH"
[ $PREFIX = "-master" ] && PREFIX=""

checkdir "${BUILDDIR}/"
makedata-all "$PREFIX" "git build"
buildall "$PREFIX" "git build"
finalize-install

cat <<EOF
**************************************************

    RocketMinsta has been built successfully
    
    Server QC progs:
        $SVPROGS
    
    Client QC progs:
        $CSPROGS
        
    CVAR defaults for server configuration:
        ${BUILDDIR}/rocketminsta.cfg
    
    Optional custom configurations:
        ${BUILDDIR}/rm-custom
$(listcustom)

    Please make sure all of these files are accessible by Nexuiz.
    Then add the following line at top of your server config:
    
        exec rocketminsta.cfg

    If you'd like to use one of the custom configurations,
    add the following at the bottom of your config:
        
        rmcustom NAME_OF_CUSTOM_CONFIG.cfg
        
    In addition, these packages MUST be available on your download server:
$(for i in $BUILT_PACKAGES;
    do echo "        $i";
done)
    
    All of them have been also installed into:
        ${BUILDDIR}/
    
    They will be added to sv_curl_serverpackages automatically.

**************************************************
EOF
