#!/usr/bin/env -S  bash -x

RESDIR=$1
RESDIR1=$1
echo RESDIR = $RESDIR

DEVICETYPE=$(cat $RESDIR\device)
printf "set title \"Increasing WSS tests\"\n" > /tmp/plotfile.plt
printf "plot \"$RESDIR/output_parsed\" using 3 with linespoints title \"$DEVICETYPE\" " >> /tmp/plotfile.plt

# If there is more than one directory/result to plot, then iterate though them and append to the plotfile
if [[ $# -gt 1 ]] ; then
	for  i in $@
	do
	   shift
	   RESDIR=$1
	   DEVICETYPE=$(cat $RESDIR\device)
	   if [ ! -f $RESDIR/output_parsed ] ; then
		   echo "!!! NO DATA !!! "
		   continue
	   fi
	   echo RESDIR = $RESDIR
	   DEVICETYPE=$(cat $RESDIR\device)
	   printf ", \"$RESDIR/output_parsed\" using 3 with linespoints title \"$DEVICETYPE\" " >> /tmp/plotfile.plt
        done
fi
echo "" >> /tmp/plotfile.plt
cat $RESDIR1/set_xtics.plt /tmp/plotfile.plt > /tmp/plot_all.plt
#gnuplot -p /tmp/plotfile.plt
gnuplot -p /tmp/plot_all.plt


