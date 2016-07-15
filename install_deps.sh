#!/bin/bash
#
# ./install_deps.sh
#
# Download vuforia-sdk-ios-5-5-9 from github releases and extracts from ZIP
#
# Helps prevent repo bloat due to large binary files
#

prefix=
foldername=external-deps
filename=vuforia-sdk-ios-5-5-9

echo Create folder $foldername
mkdir $foldername
cd $foldername
echo Downloading $filename.zip from $prefix...
curl -# -LO $prefix/$filename.zip
echo Extracting $filename.zip... please standby...
unzip -q $filename.zip
echo Cleaning up...
rm $filename.zip
echo Done.
