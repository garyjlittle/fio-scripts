#!/usr/bin/env -S bash 

###############################################
# Run the complete sweep process
#
# 1. Generate the fio files
# 2. Execute the fio scripts
# 3. Gather environment data (CPU, Instance Types, OS Version etc.)
# 4. Process the results
# 5. Plot the results
###############################################

# Pass in sweep script, base directory, list of devices

SWEEPSCRIPT=$1
BASEDIR=$2
DEVICE=$3

RESDIR=$(./$SWEEPSCRIPT -d $BASEDIR -f $DEVICE|tail -1)
sudo ./run-fio-files.sh -d $RESDIR 
./process-fio-yaml.sh -d $RESDIR

if [[ $# -gt 3 ]] ; then 
	shift
	for i in $@
	do
		shift
		DEVICE=$1
		if [[ ! -z $DEVICE ]] ; then 
			RESDIR=$(./$SWEEPSCRIPT -d $BASEDIR -f $DEVICE|tail -1)
			sudo ./run-fio-files.sh -d $RESDIR 
			./process-fio-yaml.sh -d $RESDIR
		fi
	done
fi



