#!/bin/bash

function run_pidstat(){
	time=$(date +"%Y-%m-%d_%H:%M:%S.%3N")
	pidstat -d 1 | tee -a pidstat_$time.txt

}

function run_bpftrace(){
	while true
	do
		num=0;
		io_value=40;

		for ((i=0; i<12; i++))
		do
			curtime=$(date +"%Y-%m-%d_%H-%M-%S.%3N")

			iowait=$(top -b -d 1 -1 -n 1 | grep -w "Cpu$num" | awk -F [wa] '{print $1}' | awk -F [,] '{print $5}' | awk '{print $1}')
			echo "[$curtime] Cpu$num--iowait: $iowait" | tee -a iowait_value.txt

			iowait_num=$(echo "scale=0; $iowait / 1" | bc)

			if [ $iowait_num -gt $io_value ];then
				sudo bpftrace -e 'profile:hz:99 /cpu == '$num'/ { @sample[cpu, comm, tid, pid, kstack, ustack] = count(); } interval:s:10 { exit(); }' | tee -a bpftrace_cpu$num.txt
				echo "-------------------------------------------------------------------------------------------------------------" | tee -a bpftrace_cpu$num.txt
				
			fi

			let num++
		done

	done

}

function main(){
	total_time=120
	first_time=$(date +%s)
	end_time=$((first_time + total_time * 60))

	while [ $(date +%s) -lt $end_time ]
	do

		run_pidstat &

		run_bpftrace
	done
}

main






