#!/usr/bin/env -S bash 

############################################################
# Generate a set of scripts aimed at finding various caching
# sizes using an increasing workingset size.  Based on ideas
# in IOzone
############################################################
#         Change these values to setup the experiment      # 
############################################################
# ~~~ !!!1 WSS must be expressed in MB !!!! ~~~~~          #
WSS_8m_64g=(8m 16m 32m 64m 128m 256m 512m 1024m 2048m 4096m 8192m 16384m 32768m 65536m)
WSS_8m_128g=(8m 16m 32m 64m 128m 256m 512m 1024m 2048m 4096m 8192m 16384m 32768m 65536m 131072m)
WSS=${WSS_8m_64g[*]}
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
# Write out the WSS list for use as labels
#############################################################
write_wss_info() {
 count=0
 rm $OUTPUTDIR/wss_list
 rm $OUTPUTDIR/wss_list_gnuplot
 for wss in ${WSS[@]} ; do
	 wss_mb=$(echo $wss | tr -d "m")
	 echo wss_mb = $wss_mb
	 if [ $wss_mb -ge 1024 ]; then
		 wss_gb=$(echo "$wss_mb / 1024"|bc)
		 echo "wss_gb = $wss_gb"
		 wss=$wss_gb
	 	 printf "%sg " $wss  >> $OUTPUTDIR/wss_list
		 printf "\"%sg\" %d," $wss $count  >> $OUTPUTDIR/wss_list_gnuplot
	 else 
	 	 printf "%s " $wss  >> $OUTPUTDIR/wss_list
		 printf "\"%s\" %d ," $wss $count  >> $OUTPUTDIR/wss_list_gnuplot
	 fi
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
	echo "WSS sweep tests" > $OUTPUTDIR/gnuplot_title
	echo "Working Set Size" > $OUTPUTDIR/gnuplot_xlabel
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
-d "device" which can be a file-system file or device file
\n \
-o "output" the output directory where the fio files will be written.
\n \
-b "blocksize" Blocksize passed to fio e.g. 8k or 1m  default 4k
\n \
-q "queuedepth" (iodepth) passed to fio default 64 
\n \
-r "runtime" passed to fio as is.  e.g. use 60s for 60 seconds	
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
while getopts ":o:d:b:r:h" Option
do
    case $Option in
        o   )   OUTPUTDIR=$OPTARG ;;
        d   )   DEVICE=$OPTARG ;;
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
OUTPUTDIR=$OUTPUTDIR/wss_sweep-$(basename $DEVICE)-$BS-$IODEPTH-$RUNTIME
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
write_wss_info
write_gnuplot_text
#############################################################
# Do not remove this last echo statement it is used by the runsweep
# script to determine the full output directory name.
#############################################################
echo $OUTPUTDIR
