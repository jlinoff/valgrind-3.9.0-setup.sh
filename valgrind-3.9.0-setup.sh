#!/bin/bash
#
# Control program for setting up valgrind.
#
# Here is how you use it to create a version of valgrind that uses a
# maximum of 128GB of RAM.
#
# $ ./valgrind-3.9.0-setup.sh 128
#
# It will create a build directory (valgrind-3.9.0) and a
# release directory (rtf).
#
# Here is a fairly complete example.
#
# $ mkdir -p work/valgrind/3.9.0
# $ cd work/valgrind/3.9.0
# $ wget http://projects.joelinoff.com/valgrind/valgrind-3.9.0-setup.sh
# $ ./valgrind-3.9.0-setup.sh 128 2>&1|tee log  # Build a 128GB version.
# $ ./rtf/bin/valgrind -h
#
# Copyright (c) 2014 by Joe Linoff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# ================================================================
# Functions
# ================================================================
function VgMask() {
    local a1=$1
    local a2=$2
    local val=$(( ~( (65536 - $a1) | (($a2 - 1) << 16) ) )) #
    printf "0x%X" $val
}

function VgSetup() {
    VG_SIZE_GB=$1
    VG_N_PRIMARY_BITS=13
    local x=$VG_SIZE_GB
    while (( $x > 0 )) ; do
	VG_N_PRIMARY_BITS=$(( $VG_N_PRIMARY_BITS + 1 ))
	x=$((x / 2))
    done
    VG_N_PRIMARY_MAP=$(( 1 << $VG_N_PRIMARY_BITS ))

    x=$(( (65536 * $VG_N_PRIMARY_MAP) - 1 ))
    VG_MAX_PRIMARY_ADDRESS=$(printf "0x%X" $x)

    x=$(( 1 << ($VG_N_PRIMARY_BITS + 16) )) #
    VG_ASPACEM_MAXADDR=$(printf "0x%X" $x)

    VG_MASK1=$(VgMask 1 $VG_N_PRIMARY_MAP)
    VG_MASK2=$(VgMask 2 $VG_N_PRIMARY_MAP)
    VG_MASK4=$(VgMask 4 $VG_N_PRIMARY_MAP)
    VG_MASK8=$(VgMask 8 $VG_N_PRIMARY_MAP)
    VG_N_SEGMENTS=500000
}

function hdr() {
    echo ""
    echo "# ================================================================"
    echo "# $*"
    echo "# ================================================================"
}

# ================================================================
# Main
# ================================================================
if (( $# == 1 )) ; then
    arg=$1
    case $arg in
	32|64|128|256|512|1024)
	    VgSetup $arg
	    ;;
	*)
	    echo "ERROR: invalid argument ($1), valid values are 32, 64, 128, 256, 512, 1024"
	    exit 1
	    ;;
    esac
else
    VgSetup 128  # default
fi

umask 0

rootname="valgrind-3.9.0"
tarfile="${rootname}.tar.bz2"
rempath="http://valgrind.org/downloads/$tarfile"
repofile="$tarfile"
thisdir="$(cd $(dirname .); pwd)"
rtfdir="$thisdir/rtf"

hdr "Setup"
printf "Build Setup\n"
printf "   thisdir  $thisdir\n"
printf "   rtfdir   $rtfdir\n"
printf "   tarfile  $tarfile\n"
printf "   URL      $rempath\n"
printf "\n"
printf "VG Setup\n"
printf "   VG_SIZE_GB             = %d GB\n" $VG_SIZE_GB
printf "   VG_N_PRIMARY_BITS      = %d\n"    $VG_N_PRIMARY_BITS
printf "   VG_N_PRIMARY_MAP       = 0x%X\n"  $VG_N_PRIMARY_MAP
printf "   VG_MAX_PRIMARY_ADDRESS = %s\n"    $VG_MAX_PRIMARY_ADDRESS
printf "   VG_MASK(1)             = %s\n"    $VG_MASK1
printf "   VG_MASK(2)             = %s\n"    $VG_MASK2
printf "   VG_MASK(4)             = %s\n"    $VG_MASK4
printf "   VG_MASK(8)             = %s\n"    $VG_MASK8
printf "   VG_ASPACEM_MAXADDR     = %s\n"    $VG_ASPACEM_MAXADDR
printf "   VG_N_SEGMENTS          = %d\n"    $VG_N_SEGMENTS

if [ ! -f $tarfile ] ; then
    hdr "Download"
    wget $rempath -O $tarfile
fi

if [ ! -d $rootname ] ; then
    hdr "extracting"
    tar jxf $repofile

    # cd to work directory
    cd $rootname
    pwd

    # Fix coregrind/m_aspacemgr/aspacemgr-linux.c
    SRC="coregrind/m_aspacemgr/aspacemgr-linux.c"
    hdr "fixing $SRC"
    DTS=$(date +'%Y%m%d%H%M%S')
    if [ -f $SRC ] ; then
	BACKUP=$SRC.orig.$DTS
	cp $SRC $BACKUP
	sed -e "s@\(# *define VG_N_SEGMENTS*\).*\$@\1 $VG_N_SEGMENTS@g" \
	    -e "s@\(aspacem_maxAddr = (Addr)\).*\$@\1 ${VG_ASPACEM_MAXADDR}ULL - 1; /* $VG_SIZE_GB GB */@g" \
	    $BACKUP >$SRC
    fi

    # Fix memcheck/mc_main.c
    SRC=memcheck/mc_main.c
    hdr "fixing $SRC"
    DTS=$(date +'%Y%m%d%H%M%S')
    if [ -f $SRC ] ; then
	BACKUP=$SRC.orig.$DTS
	cp $SRC $BACKUP
	sed -e "s@\(# *define *N_PRIMARY_BITS\).*\$@\1 $VG_N_PRIMARY_BITS  /* $VG_SIZE_GB GB */@g" \
	    -e "s@\(tl_assert(MAX_PRIMARY_ADDRESS ==\).*\$@\1 ${VG_MAX_PRIMARY_ADDRESS}ULL); /* $VG_SIZE_GB GB\* */@g" \
	    -e "s@\(tl_assert(MASK(1) == \)0x.*\$@\1${VG_MASK1}ULL); /* $VG_SIZE_GB GB\* */@g" \
	    -e "s@\(tl_assert(MASK(2) == \)0x.*\$@\1${VG_MASK2}ULL); /* $VG_SIZE_GB GB\* */@g" \
	    -e "s@\(tl_assert(MASK(4) == \)0x.*\$@\1${VG_MASK4}ULL); /* $VG_SIZE_GB GB\* */@g" \
	    -e "s@\(tl_assert(MASK(8) == \)0x.*\$@\1${VG_MASK8}ULL); /* $VG_SIZE_GB GB\* */@g" \
	    $BACKUP >$SRC
    fi

    hdr "configuration options"
    ./configure --help

    hdr "configuring..."
    ./configure --prefix=$rtfdir

    # Build and install.
    hdr "building and installing..."
    make
    make install

    # Copy over the man pages.
    mkdir -p $rtfdir/man/man1
    cp docs/*.1 $rtfdir/man/man1
    hdr "done building"
fi

hdr "test"
test_cmd="$rtfdir/bin/valgrind --version"
echo "$test_cmd"
$test_cmd
st=$?
if (( $st == 0 )) ; then
    echo "test: passed"
else
    echo "test: failed"
fi

hdr "done"
exit $st
