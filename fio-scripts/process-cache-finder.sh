#!/usr/bin/env  bash 

########################################################
#
# Run the fio scripts generated by generate-cache-finder
#
########################################################

while getopts ":d:d:v" Option
do
    case $Option in
        d   )   OUTPUTDIR=$OPTARG ;;
        d   )   DEVICE=$OPTARG ;;
        v   )   VERBOSE=1 ;;
        ?   )   echo "Unknown argument $OPTARG" ; exit ;;
    esac
done
if [ -z $OUTPUTDIR  ] 
then
	echo "Need to use -d for output directory"
	exit 1
fi

pushd . >/dev/null
cd $OUTPUTDIR
rm output_parsed
echo "----------------------------------------------------------------------------"
cat environment
echo "----------------------------------------------------------------------------"
printf "%-4s %-8s %-9s %-9s %-4s %-4s\n" bs  filesize iops   lat_ns usr sys 
for json in $(ls *.fio.out.json|sort -n)
do
    iops_mean=$(jq  '.["jobs"][0]["read"]["iops_mean"]' $json)
    iops=$( jq '.["jobs"][0]["read"]["iops"]' $json)
    filesize=$( jq '.["jobs"][0]["job options"]["size"]' $json)
    usr_cpu=$(jq '.["jobs"][0]["usr_cpu"]' $json)
    sys_cpu=$(jq '.["jobs"][0]["sys_cpu"]' $json)
    clat_ns=$(jq '.["jobs"][0]["read"]["clat_ns"]["mean"]' $json)
    iodepth=$(jq '.["global options"]["iodepth"]' $json)
    bs=$(jq '.["global options"]["bs"]' $json)

    printf "%4s %-8s %1.0f %10.0f %4.0f %4.0f\n" $bs $filesize $iops_mean $clat_ns $usr_cpu $sys_cpu | tee -a output_parsed
done
# Generate little gnuplot script
DEVICE=$(cat device)
echo 'set terminal dumb' > plotfile.plt
echo "plot 'output_parsed' using 3 with linespoints title \"$DEVICE\"" >> plotfile.plt
gnuplot -p plotfile.plt
popd




