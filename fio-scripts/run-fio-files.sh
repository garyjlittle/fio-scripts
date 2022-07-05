#!/usr/bin/env bash

########################################################
#
# Run the fio scripts located in the given directory. 
# send the output of fio to a yaml output file in the 
# same directory using the format <fiofilename>.out.json
# 
# The fio files will be run in the order of their sort
# order (sort -n).  So to order the fio files use something
# like 1-randread.fio, 2-randwrite.fio to set a particular
# ordering
#
# The yaml output files can be parsed and plotted using
# the process-fio.sh scripts.
#
########################################################
help() { echo "$0 -d <fio files dir> (The directory containing the fio files)" ; exit 0 ;}
while getopts ":d:hv" Option
do
    case $Option in
        d   )   OUTPUTDIR=$OPTARG ;;
        h   )   help ;;
        v   )   VERBOSE=1 ;;
        ?   )   echo "Unknown argument $OPTARG" ; exit ;;
    esac
done
if [ ! -z $OUTPUTDIR  ]; then echo "The fio directory is $OUTPUTDIR" 
else
	echo "No Directory provided.  Use -d to point to a directory containing fio files."
	exit 1
fi

pushd .
cd $OUTPUTDIR
for script in $(ls *.fio|sort -n)
do
    echo fio $script --output-format=json -o $script.out.json
    fio $script --output-format=json -o $script.out.json
done
popd
