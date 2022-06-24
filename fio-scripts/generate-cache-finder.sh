#!/usr/bin/env bash

############################################################
#
# Generate a set of scripts aimed at finding various caching
# sizes using an increasing workingset size.  Based on ideas
# in IOzone
##############################################################
WSS_FULL=(8m 16m 32m 64m 128m 256m 512m 1g 2g 4g 8g 16g 32g 64g 128g 512g 1024g 2048g 4192g)
WSS_SMALL=(8m 16m 32m 64m 128m 256m 512m 1g)
WSS=${WSS_FULL[*]}
#Define block sizes
BS=4k
#Define queue depth
IODEPTH=64
#Define runtime per iteration
RUNTIME=15s
#Define RW pattern
RW=randread


#############################################################
#
# Normally wont need to change these
#
#############################################################
#Define random style
RANDOM_DISTRIBUTION=random
#Define IO Engine
IOENGINE=libaio
#Define pagecache interaction
DIRECT=1


#############################################################
#
# Take some parameters from the command line
#
#############################################################
usage() {
	printf "Usage: $0 -d <output directory> -f <file or device name> -h Get Help\n\n"
}
help() { 
	printf "This script generates a set of fio files that can be used to generate IO across a \
range of working set sizes wss.\n\n \
-f "filename" which can be a file-system file or device file
\n \
-d "directory" the output directory where the fio files will be written. \n\n\
After creating the fio files, the script run-cache-finder.sh can be run to execute the fio files in order\n\n"
	exit 1
}
#Check for empty argument list
[[ $# -eq 0 ]] && { usage ; exit 1; }

while getopts ":f:d:h" Option
do
    case $Option in
        d   )   OUTPUTDIR=$OPTARG ;;
        f   )   DEVICE=$OPTARG ;;
        h   )   help ;;
	*   )   echo usage ;;
    esac
done

if [ -z $OUTPUTDIR  ]; then 
    echo "The output directory is empty"
    exit 1
fi

if [ -z $DEVICE ]; then 
   echo "No device given, bailing out"
   exit
fi

# Save current directory and change to the outputdirectory.
pushd . >/dev/null
if [[ -d $OUTPUTDIR ]] ; then
	echo found directory $OUTPUTDIR
	cd $OUTPUTDIR
else
	echo making directory $OUTPUTDIR
	mkdir $OUTPUTDIR || exit 1
fi
let count=0
for wss in ${WSS[@]}; do
    ((count++))
    echo "
[global]
bs=$BS
rw=$RW
iodepth=$IODEPTH
time_based
runtime=$RUNTIME
ioengine=$IOENGINE
direct=$DIRECT
random_distribution=$RANDOM_DISTRIBUTION

[$RW-1]
filename=$DEVICE
size=$wss
" > $count-$BS-$RW-$wss-$IODEPTH"qd".fio
done

# Restore to previous directory
popd > /dev/null
echo fio files created in $OUTPUTDIR
