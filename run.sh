#!/usr/bin/env bash
function run_workload() {
	threads=$1
	msg=$2
	for nthr in $threads; do
		export nthr
		for msgsize in $msg; do 
			export msgsize
			curlrc=1
			while [ $curlrc != 0 ]; do
				curl --retry 6 -X POST ${syncserver}:8080 -H 'Content-Type: application/son' -d '{}' 2>/dev/null
				curlrc=$?
			done
			echo "Running ${workload} | ${nthr} threads | msg ${msgsize} at $(date +"%T.%3N")" 
			uperf -t -i 65 -m ${workload}.xml > output/${workload}/i${nthr}_m${msgsize}.out	
			if [ $? != 0 ]; then
				arp -a
				cat output/${workload}/i${nthr}_m${msgsize}.out
			fi
		done 
	done 
}

function print_results() {
	threads=$1
	msg=$2
	echo "Results for ${workload}"
	for nthr in $threads; do
		for msgsize in $msg ; do
			if [ $workload == "rr" ]; then
				awk -F' ' '/Txn2/  {var = var sep $8; sep=","} END {printf "%s", var}' output/${testname}/i${nthr}_m${msgsize}.out  
			else
				awk -F' ' '/Txn2/  {var = var sep $7; sep=","} END {printf "%s", var}'  output/${workload}/i${nthr}_m${msgsize}.out 
			fi
		done 
		echo "" 
	done 
}


test_set=${TEST_SET:-"stream maerts bidi rr"}
message_opts=${MESSAGE_OPTS:-"256 1k 4k 16k 64k"}
threads_opts=${THREADS_OPTS:-"1 4 8 16 64"}
rr_message_opts=${RR_MESSAGE_OPTS:-"1 1k 4k 16k 64k"}
rr_threads_opts=${RR_THREADS_OPTS:-"1 25 50 100 150"}


rc=1

# tries to perform a simple connection to the remote host to make sure both
# sides are up and running
while [ $rc -ne 0 ]; do
	uperf -m connect.xml
	rc=$?
done

for testname in $test_set; do
	export workload=$testname
	if [ testname == "rr" ]; then
		threads=$rr_threads_opts
		msg=$rr_message_opts
	else
		threads=$threads_opts
		msg=$message_opts
	fi
	run_workload $threads $msg
	print_results $threads $msg
done
