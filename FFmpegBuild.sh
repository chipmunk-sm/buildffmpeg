#!/bin/sh

set -e

tmpexitcode=0

BUILDPROFILE=$1

ROOT_DIR=$2
BIN_DIR="${ROOT_DIR}/${BUILDPROFILE}_bin"
PREF_DIR="${ROOT_DIR}/${BUILDPROFILE}_pref"

rm -rf $BIN_DIR
mkdir $BIN_DIR

rm -rf $PREF_DIR
mkdir $PREF_DIR

yasm.exe --version
echo "**** which yasm   $(which yasm)"
echo "**** which cl     $(which cl)"   
echo "**** which link   $(which link)"         
echo "**** which make   $(which make)"             

set +e

if [ -e "/usr/bin/link" ]; then
	mv "/usr/bin/link" "/usr/bin/link.bac"
fi

#********* cd to source dir ************
pushd "$PREF_DIR"

#********* CONFIGURE ************
if [ "$BUILDPROFILE" == "Win10x86" ]; then
    "${ROOT_DIR}/ffmpeg/configure" --arch=x86 --toolchain=msvc --target-os=win32 --enable-cross-compile --enable-asm --enable-x86asm --prefix="$PREF_DIR" --bindir=$BIN_DIR
elif [ "$BUILDPROFILE" == "Win10x64" ]; then 
    "${ROOT_DIR}/ffmpeg/configure" --arch=x86_64 --toolchain=msvc --target-os=win32 --enable-cross-compile --enable-asm --enable-x86asm --prefix="$PREF_DIR" --bindir=$BIN_DIR
elif [ "$BUILDPROFILE" == "Win8x86" ]; then 
    "${ROOT_DIR}/ffmpeg/configure" --arch=x86 --toolchain=msvc --target-os=win32 --enable-cross-compile --enable-asm --enable-x86asm --prefix="$PREF_DIR" --bindir=$BIN_DIR
elif [ "$BUILDPROFILE" == "Win8x64" ]; then 
    "${ROOT_DIR}/ffmpeg/configure" --arch=x86_64 --toolchain=msvc --target-os=win32 --enable-cross-compile --enable-asm --enable-x86asm --prefix="$PREF_DIR" --bindir=$BIN_DIR
fi
 
tmpexitcode=$?

lastcommand="configure $BUILDPROFILE"
   
#********* MAKE INSTALL ************
if [ $tmpexitcode -eq 0 ]; then
    echo "****** RUN make install "
    make -j4 install
    tmpexitcode=$?
    lastcommand="make install"
fi

#********* cd to root folder ************
popd

#********* COLLECT DLL ************
if [ -d "$PREF_DIR/bin" ]; then
    if [ $tmpexitcode -eq 0 ]; then
        echo "****** COLLECT DLL "
        cp "$PREF_DIR/bin/*.dll" "$BIN_DIR/"
        tmpexitcode=$?
        lastcommand="copy dll"
    fi
fi

#********* RETURN BACK /usr/bin/link ************
if [ -e "/usr/bin/link.bac" ]; then
	mv "/usr/bin/link.bac" "/usr/bin/link"
fi

#********* echo if error ************
if [ $tmpexitcode -ne 0 ]; then
    echo "\"${lastcommand}\" failed! exit code [${tmpexitcode}]"
fi

if [ $tmpexitcode -eq 0 ]; then
    echo "Build OK."
fi

exit $tmpexitcode
