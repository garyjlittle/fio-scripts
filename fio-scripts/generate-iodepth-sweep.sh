#!/usr/bin/env -S bash 

############################################################
# Generate a set of scripts aimed at finding the optimal
# iodepth / concurrency for a given io size.
############################################################
#         Change these values to setup the experiment      # 
############################################################
#Define the workingset size - can be overridden by -w switch.
WSS=1024m
#Define this list of IO/queue depth parameters
IODEPTH=(1 2 4 8 16 32 64 128 256)
#Define block sizes - can be overridden with -b switch.
BS=4k
#Define runtime per iteration can be overridden with -r switch
RUNTIME=10s
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
	for this_iodepth in ${IODEPTH[@]}; do
	    ((count++))
	    echo "
[global]
bs=$BS
rw=$RW
iodepth=$this_iodepth
time_based
runtime=$RUNTIME
ioengine=$IOENGINE
direct=$DIRECT
random_distribution=$RANDOM_DISTRIBUTION

[$RW-1]
filename=$DEVICE
size=$wss
" > $count-$BS-$RW-$wss-$this_iodepth"qd".fio
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
# Write out the IODEPTH list for use as labels
#############################################################
write_iodepth_info() {
 count=0
 rm $OUTPUTDIR/wss_list
 rm $OUTPUTDIR/wss_list_gnuplot
 for wss in ${IODEPTH[@]} ; do
	 wss_mb=$(echo $wss | tr -d "m")
	 echo wss_mb = $wss_mb
	 	 printf "%s " $wss  >> $OUTPUTDIR/wss_list
		 printf "\"%s\" %d," $wss $count  >> $OUTPUTDIR/wss_list_gnuplot
	 ((count++))
 done
printf "\n" >> $OUTPUTDIR/wss_list 
printf "\n" >> $OUTPUTDIR/wss_list_gnuplot
wss_list_gnuplot=$(cat $OUTPUTDIR/wss_list_gnuplot)
echo wss_list_gnuplot = $wss_list_gnuplot

#printf "set xtics (%s)" $wss_list_gnuplot  >> $OUTPUTDIR/set_xtics.plt
echo "set xtics ($wss_list_gnuplot)" >> $OUTPUTDIR/set_xtics.plt
}

#############################################################
# Write out gnuplot text for this sweep type
#############################################################
write_gnuplot_text() {
echo "IO Depth sweep tests" > $OUTPUTDIR/gnuplot_title
echo "Queue Depth" > $OUTPUTDIR/gnuplot_xlabel
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
	printf "Usage: $0 -d <output directory> -f <file or device name> -b <blocksize> -r <runtime> \n\t-h Get Help\n\n"
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
-r "runtime" passed to fio default 10s
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
while getopts ":f:d:b:r:h" Option
do
    case $Option in
        d   )   OUTPUTDIR=$OPTARG ;;
        f   )   DEVICE=$OPTARG ;;
        b   )   BS=$OPTARG ;;
        q   )   IODEPTH=$OPTARG ;;
        r   )   RUNTIME=$OPTARG ;;
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
OUTPUTDIR=$OUTPUTDIR-iodepth_sweep-$(basename $DEVICE)-$BS-iosize
if [[ -d $OUTPUTDIR ]] ; then
	echo found directory $OUTPUTDIR
 	if [[ -f wss_list ]] ; then rm wss_list ; fi
 	if [[ -f wss_list_gnuplot ]] ; then rm wss_list_gnuplot ; fi
 	if [[ -f set_xtics.plt ]] ; then rm set_xtics.plt ; fi
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
write_iodepth_info
write_gnuplot_text
#############################################################
# Do not remove this last echo statement it is used by the runsweep
# script to determine the full output directory name.
#############################################################
echo $OUTPUTDIR
#############################################################
