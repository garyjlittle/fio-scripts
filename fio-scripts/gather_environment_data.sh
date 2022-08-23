#!/usr/bin/env -S bash


while getopts "d:f:" Option
do
	case $Option in 
		d ) OUTPUTDIR=$OPTARG ;;
		f ) DEVICE=$OPTARG ;;
	esac
done

if [ -z $OUTPUTDIR  ]; then
    echo "The output directory is not specified"
    exit 1
fi

if [ -z $DEVICE ]; then
   echo "No device given, bailing out"
   exit
fi


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

write_environment

