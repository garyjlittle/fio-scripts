#!/usr/bin env bash

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
BS=64k
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
while getopts ":o:d:v" Option
do
    case $Option in
        o   )   OUTPUTDIR=$OPTARG ;;
        d   )   DEVICE=$OPTARG ;;
        v   )   VERBOSE=1 ;;
        ?   )   echo "Unknown argument $OPTARG" ; exit ;;
    esac
done
if [ ! -z $OUTPUTDIR  ]; then echo "The Destination is $OUTPUTDIR" ; fi
if [ ! -z $DEVICE ]; then 
    echo "The Device is $DEVICE" 
else
   echo "No device given, bailing out"
   exit
fi

# Save current directory
pushd .
cd $OUTPUTDIR

for wss in ${WSS[@]}; do
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
" > $BS-$RW-$wss-$IODEPTH"qd".fio
done

# Restore to previous directory
popd
