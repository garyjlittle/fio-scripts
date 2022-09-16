#!/usr/bin/env bash

LIBDIR=$(dirname $0)/lib
echo LIBDIR=$LIBDIR
source $LIBDIR/get_device_size.sh
source $LIBDIR/is_mounted.sh

SIZE=$(getDiskSize "/dev/sdc")

echo The size is $SIZE


if  $(is_mounted) ; then
       echo "Disk is mounted, bailing out"
	exit 1
fi

echo "Disks is not mounted - going ahead"
	
