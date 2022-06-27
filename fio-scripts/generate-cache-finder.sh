#!/usr/bin/env -S bash 

############################################################
# Generate a set of scripts aimed at finding various caching
# sizes using an increasing workingset size.  Based on ideas
# in IOzone
############################################################
#         Change these values to setup the experiment      # 
############################################################
# ~~~ !!!1 WSS must be expressed in MB !!!! ~~~~~          #
WSS_FULL=(8m 16m 32m 64m 128m 256m 512m 1g 2g 4g 8g 16g 32g 64g 128g 512g 1024g 2048g 4192g)
WSS_SMALL=(8m 16m 32m 64m 128m 256m 512m 1024m 114479m)
WSS=${WSS_SMALL[*]}
#Define block sizes - can be overridden with -b switch.
BS=4k
#Define queue depth - can be overridden with -q switch 
IODEPTH=64
#Define runtime per iteration
RUNTIME=15s
#Define RW pattern
RW=randread

#############################################################
#        Normally wont need to change these                 #
#############################################################
#Define random style
RANDOM_DISTRIBUTION=random
#Define IO Engine
IOENGINE=libaio
#Define pagecache interaction
DIRECT=1

#############################################################
# Main function that does the work of creating fio files in
# the destination directory
#############################################################
write_fio_file() {
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
}

#############################################################
# Gather information about the environment
#############################################################
write_environment() {
echo OUTPUTDIR=$OUTPUTDIR
ENVFILE=$OUTPUTDIR/environment
HOSTNAME=$(hostname)
DEVICETYPE=$(lsscsi | grep $DEVICE | awk '{for(i=3;i<=NF;++i)print $i}' | tr '\n' ' ')
CPUTYPE=$(cat /proc/cpuinfo |grep "model name"|uniq)
CPUCORES=$(cat /proc/cpuinfo |grep "cores"|uniq)
OSVER=$(uname -rv)
echo $HOSTNAME > $ENVFILE
echo $DEVICETYPE >> $ENVFILE
echo $CPUTYPE >> $ENVFILE
echo $CPUCORES >> $ENVFILE
echo $OSVER >> $ENVFILE
echo $DEVICETYPE > $OUTPUTDIR/device
}
#############################################################
# Get max size for this device
#############################################################
getdisksize() {
DEVICEBYTES=$(lsblk -ib $DEVICE |grep $(basename $DEVICE)|head -1|awk '{ print $4 }')
DEVICEMB=$( echo "$DEVICEBYTES / (1024*1024)" | bc)
echo DEVICE in MB = $DEVICEMB
}
checksize() {
        for wss in ${WSS[@]}; do
		wss_mb=$(echo $wss | tr -d 'm')
		if [ $wss_mb -gt $DEVICEMB ] ; then
			echo "Configured WSS $wss is greater than Device size $DEVICEMB"
			exit 1
		fi
	done
}
#############################################################
# Create usage and help functions, also check for empty 
# values for the required parameters (-d and -f)
#############################################################
usage() {
	printf "Usage: $0 -d <output directory> -f <file or device name> -b <blocksize> -h Get Help\n\n"
}
help() { 
	printf "\n\nThis script generates a set of fio files that can be used to generate IO across a \
range of working set sizes wss.\n\n \
-f "filename" which can be a file-system file or device file
\n \
-d "directory" the output directory where the fio files will be written.
\n \
-b "blocksize" Blocksize passed to fio e.g. 8k or 1m  default 4k
\n \
-q "queuedepth" (iodepth) passed to fio default 64 
\n \
After creating the fio files, the script run-cache-finder.sh can be run to execute the fio files in order\n\n"
	exit 1
}
#Check for empty argument list
[[ $# -eq 0 ]] && { usage ; exit 1; }

#############################################################
#
# Take some parameters from the command line.  Namely the
# destination directory where the fio files will be written
# to (-d) and the file/device under test (-f).  It is 
# probably best to have the user specify the file on the 
# command line to avoid accidentally overwriting a mounted
# filesystem / device.
#
#############################################################
while getopts ":f:d:b:h" Option
do
    case $Option in
        d   )   OUTPUTDIR=$OPTARG ;;
        f   )   DEVICE=$OPTARG ;;
        b   )   BS=$OPTARG ;;
        q   )   IODEPTH=$OPTARG ;;
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
OUTPUTDIR=$OUTPUTDIR-wss-$(basename $DEVICE)-$BS-$IODEPTH
if [[ -d $OUTPUTDIR ]] ; then
	echo found directory $OUTPUTDIR
	cd $OUTPUTDIR
else
	echo making directory $OUTPUTDIR
	mkdir $OUTPUTDIR || exit 1
	cd $OUTPUTDIR
fi
#############################################################
# Finally do the work of creating the fio file and writing
# it out to the requested directory for later use
#############################################################
getdisksize
checksize
write_fio_file
write_environment
