#!/bin/bash

function explain_json(){
	js_name="monitor_plus"

	json_data=$(cat $"$js_name".json)
        number=$(echo "$json_data" | jq -r '.share_info.number')
	
	total_time=$(echo "$json_data" | jq -r '.share_info.total_time')
	echo "total_time: $total_time"
	
	start_time=$(echo "$json_data" | jq -r ".share_info.start_time")
	echo "start time: $start_time(s)"

	step=$(echo "$json_data" | jq -r ".share_info.step")
        echo "step: $step"

	frequency=$(echo "$json_data" | jq -r ".share_info.frequency")
        echo "frequency: $frequency"

        sample_time=$(echo "$json_data" | jq -r ".share_info.sample_time")
        echo "sample_time: $sample_time"
	
	x=1
	for((i=0; i<$number; i++))
	do
		json_data=$(cat $"$js_name".json)
        	mode=$(echo "$json_data" | jq -r ".monitor_$x.mode")
		app=$(echo "$json_data" | jq -r ".monitor_$x.app_name")
		thread=$(echo "$json_data" | jq -r ".monitor_$x.thread_name")
		if [ $mode = "process_monitor" ]
		then
			echo "you want to monitor: [ $app---$mode ]"
		elif [ $mode = "thread_monitor" ]
		then
			echo "you want to monitor: [ $app---$thread---$mode ]"
		elif [ $mode = "cpu_time_monitor" ]
		then
			core_index=$(echo "$json_data" | jq -r ".monitor_$x.core_index")
			echo "you want to monitor: [ cpu_$core_index---$mode ]"
		else
			core_index=$(echo "$json_data" | jq -r ".monitor_$x.core_index")
			echo "you want to monitor: [ cpu_$core_index---$mode ]"
		fi

		let x++
	done

	#echo "you want to monitor: $mode"
}

function init_array(){
	array=() #更新阈值用
	for((i=0; i<$number; i++))
	do
        	array[i]=0
	done

	echo "初始化cpu阈值：${array[@]}"
}

function get_pid(){
	pidof $app_name
}

function get_json_base_data(){
	json_data=$(cat $"$js_name".json)
        number=$(echo "$json_data" | jq -r '.share_info.number')

        echo "the number of apps is: $number"

        #flag=0
        #cpu_tmp=0
        #s=1

	#start_time=$(echo "$json_data" | jq -r ".share_info.start_time")
	#echo "start time: $start_time(s)"

        #total_time=$(echo "$json_data" | jq -r ".share_info.total_time")
	#echo "total_time: $total_time"

        #step=$(echo "$json_data" | jq -r ".share_info.step")
        #echo "step: $step"

        #frequency=$(echo "$json_data" | jq -r ".share_info.frequency")
        #echo "frequency: $frequency"

        #sample_time=$(echo "$json_data" | jq -r ".share_info.sample_time")
        #echo "sample_time: $sample_time"

        #long=0
        #run_time=`expr $total_time \* 60`

        datetime=$(date +%H:%M:%S)
        echo ${datetime}
}

function explain_json_cpu(){
        #js_name="monitor_plus"
        json_data=$(cat $"$js_name".json)
        mode=$(echo "$json_data" | jq -r ".monitor_$x.mode")
        core_index=$(echo "$json_data" | jq -r ".monitor_$x.core_index")
        issue_time=()
        issue_time[0]=$(echo "$json_data" | jq -r " .monitor_$x.issue_time[0]")
        issue_time[1]=$(echo "$json_data" | jq -r " .monitor_$x.issue_time[1]")
        issue_time[2]=$(echo "$json_data" | jq -r " .monitor_$x.issue_time[2]")
        issue_time[3]=$(echo "$json_data" | jq -r " .monitor_$x.issue_time[3]")
       	issue_time[4]=$(echo "$json_data" | jq -r " .monitor_$x.issue_time[4]")
        echo "moments:"
       	echo ${issue_time[@]}
}

function calculate_moments(){
        c=0
        count=0
        for((i=0;i<5;i++))
        do
                IFS=':' read -ra time_parts <<< "${issue_time[$c]}"

                if [[ -n ${time_parts[0]} && -n ${time_parts[1]} && -n ${time_parts[2]} ]]
                then
                        #echo "有效时间"
                        let count++
                #else
                #echo "无效时间"
                #echo ${issue_time[$c]}

                fi
                let c++
        done

        echo "you want to monitor $count moments of CPU"
}


function get_app_data_p(){
	 json_data=$(cat $"$js_name".json)

         echo "################################################################"

         datetime=$(date +%H:%M:%S)
         echo ${datetime}

         app_name=$(echo "$json_data" | jq -r ".monitor_$x.app_name")
         echo "app_name: $app_name"

         soc_name=$(echo "$json_data" | jq -r ".monitor_$x.soc")
         echo "soc_name: $soc_name"

         threshold=$(echo "$json_data" | jq -r ".monitor_$x.threshold_${app_name}")
         echo "threshold_$app_name: $threshold"

         pid_num=$(get_pid)
         echo ">>>>>>>>>>>>pid: "$pid_num

         echo "----- ----- -----"

         echo "file task pid:$pid_num"

	 tmp=$(top -b -d 2 -n 1 -p $pid_num | tail -n 1)
	 tmp_top=$(top -b -d 2 -n 1 -p $pid_num)
	 echo "top信息：$tmp"
	 if [ -z "$tmp" ]
	 then
		 echo "原始top信息，tmp_top：$tmp_top"
	 fi

	 task_name=$(echo $tmp | awk '{print $12}' )
         echo "file task_name:$task_name"

	 #echo "$(top -b -d 2 -n 1 | grep "$app_name")"

         cpu_usage=$(echo $tmp | awk '{print $9}' )
         echo "file task cpu usage:$cpu_usage"

         cpu=$cpu_usage

         echo "$cpu"
         cpu_num=$(echo "scale=0; $cpu / 1" | bc)
         echo "cpu占用率为：$cpu_num"

         echo "----- ----- -----"
}

function get_app_data_t(){
	 json_data=$(cat $"$js_name".json)

	 echo "app_data_t:$x"

         echo "################################################################"
			
         datetime=$(date +%H:%M:%S)
         echo ${datetime}

         app_name=$(echo "$json_data" | jq -r ".monitor_$x.app_name")
         echo "app_name: $app_name"

	 thread_name=$(echo "$json_data" | jq -r ".monitor_$x.thread_name")
	 echo "thread_name: $thread_name"

         threshold=$(echo "$json_data"  | jq -r ".monitor_$x.threshold_${thread_name}")
         echo "threshold_$thread_name: $threshold"

         soc_name=$(echo "$json_data" | jq -r ".monitor_$x.soc")
         echo "soc_name: $soc_name"

	 tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $1}' )
         echo ">>>>>>>>>>>>tid: "$tid_num
	 
	 if [ -z "$tid_num" ]
	 then
	 	echo "重新获取tid"
		tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
		echo ">>>>>>>>>>>>tid: "$tid_num
	 		
		if [ -n "$tid_num" ]
		then
			echo "get tid successfully"
						
		fi

	 	echo "再次获取/确认tid"
	 	tid_num=$(ps -T -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
	 	echo ">>>>>>>>>>>>tid: "$tid_num
	 fi
	 
	 if [ -z "$tid_num" ]
	 then
		echo "该线程$thread_name未被拉起"
	 
         	echo "----- ----- -----"
	 else
         	echo "file task tid:$tid_num"

	 	tmp=$(top -b -H -d 2 -n 1 | grep "$tid_num")
	 	echo "$tmp"

	 	task_name=$(echo $tmp | awk '{print $12}' )
         	echo "file task_name:$task_name"

	 	#echo "$(top -b -H -d 2 -n 1 | grep "$tid_num")"

         	cpu_usage=$(echo $tmp | awk '{print $9}' )
         	echo "file task cpu usage:$cpu_usage"

         	cpu=$cpu_usage

         	echo "$cpu"
         	cpu_num=$(echo "scale=0; $cpu / 1" | bc)
         	echo "cpu占用率为：$cpu_num"
	 fi

         echo "----- ----- -----"
}

function get_p_perf_data(){
	 max=$threshold
	 #echo $max
	 echo "当前$app_name阈值：${array[$s-1]}"
	 echo ${array[@]}
         if [ $cpu_num -gt $max ]
         then
                if [ $cpu_num -gt ${array[$s-1]} ]
                then

                        echo "OK! Start grasping..."

                        sudo /home/mazu/perf record -F 499 -p $pid_num -o ${task_name}_${cpu_usage}_${datetime}.data -g -- sleep $sample_time
               	        sudo /home/mazu/perf script -i ${task_name}_${cpu_usage}_${datetime}.data > ${task_name}_${cpu_usage}_${datetime}.unfold
			#~/app/FlameGraphe/stackcollapse-perf.pl ${task_name}_${datetime}.unfold > ${task_name}_${datetime}.folded
			#~/app/FlameGraph/flamegraph.pl ${task_name}_${datetime}.folded > ${task_name}_${cpu_usage}_${datetime}.svg

			echo "$(top -b -d 2 -n 1 -p $pid_num | tail -n 1)"

                        array[$s-1]=`expr $cpu_num + $step`
			array_reset=`expr $threshold + $array_max`
			
			if [ ${array[$s-1]} -gt $array_reset ]
			then
				array[$s-1]=$max
			fi

                        echo "更新的阈值为：${array[@]}"

                        echo "$app_name finish!"

                 else
                        echo "$app_name未达到更新的cpu阈值！"


                 fi
      	 else

                 echo "$app_name未达到cpu阈值！"

         fi

         #if [ $long -ge $run_time ]
         #then
         #	exit
         #fi
}

function get_t_perf_data(){
	 if [ -z "$tid_num" ]
	 then
		 echo "no data"
	 else

	 	max=$threshold

         	if [ $cpu_num -gt $max ]
         	then
                	if [ $cpu_num -gt ${array[$s-1]} ]
                	then

                        	echo "OK! Start grasping..."


                        	sudo /home/mazu/perf record -F "$frequency" -t "$tid_num" -o ${task_name}_${cpu_usage}_${datetime}_thread.data -g -- sleep "$sample_time"
                        	sudo /home/mazu/perf script -i ${task_name}_${cpu_usage}_${datetime}_thread.data > ${task_name}_${cpu_usage}_${datetime}_thread.unfold
				#~/app/FlameGraph/stackcollapse-perf.pl ${task_name}_${datetime}_thread.unfold > ${task_name}_${datetime}_thread.folded
				#~/app/FlameGraph/flamegraph.pl ${task_name}_${datetime}_thread.folded > ${task_name}_${pid}_${cpu_usage}_${datetime}_thread.svg
			
				echo "$(top -b -H -d 2 -n 1 | grep "$tid_num")"

                        	array[$s-1]=`expr $cpu_num + $step`
				array_reset=`expr $threshold + $array_max`
			
				if [ ${array[$s-1]} -gt $array_reset ]
				then
					array[$s-1]=$max
				fi

                        	echo "更新的阈值为：${array[@]}"


                        	echo "$thread_name finish!"

                 	else
                        	echo "$thread_name未达到更新的cpu阈值！"


                 	fi
      	 	else

                 	echo "$thread_name未达到cpu阈值！"

         	fi
	 fi

         #if [ $long -ge $run_time ]
         #then
         #	exit
         #fi
}

function get_cpu_perf_data(){
	 max=$cpu_value
	 #echo $max
	 #echo "当前cpu$core_index阈值：${array[$s-1]}"
	 #echo ${array[@]}

	 paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
	 echo "perf_event_paranoid: $paranoid"
	 restrict=$(cat /proc/sys/kernel/kptr_restrict)
	 echo "kptr_restrict: $restrict"
			
	 if [ $paranoid == "-1" ]
	 then
		 echo "Unrestricted!"
	 else
		 echo -1 > /proc/sys/kernel/perf_event_paranoid
		 echo 0 > /proc/sys/kernel/kptr_restrict
		 paraniod=$(cat /proc/sys/kernel/perf_event_paranoid)
		 echo "perf_event_paraniod: $paraniod"
		 restrict=$(cat /proc/sys/kernel/kptr_restrict)
		 echo "kptr_restrict: $restrict" 

	 fi

         if [ $cpu_value_num -gt $max ]
         then
                if [ $cpu_value_num -gt ${array[$s-1]} ]
                then

                        echo "OK! Start grasping..."

                        sudo /home/mazu/perf record -F 499 -C $core_index -o cpu_${core_index}_${cpu_value_num}_${datetime}.data -g -- sleep $sample_time
               	        sudo /home/mazu/perf script -i cpu_${core_index}_${cpu_value_num}_${datetime}.data > cpu_${core_index}_${cpu_value_num}_${datetime}.unfold
			#~/app/FlameGraphe/stackcollapse-perf.pl ${task_name}_${datetime}.unfold > ${task_name}_${datetime}.folded
			#~/app/FlameGraph/flamegraph.pl ${task_name}_${datetime}.folded > ${task_name}_${cpu_usage}_${datetime}.svg

			#echo "$(top -b -d 2 -n 1 -p $pid_num | tail -n 1)"

                        #array[$s-1]=`expr $cpu_num + $step`
			array_reset=`expr $cpu_value + $array_max`
			
			if [ ${array[$s-1]} -gt $array_reset ]
			then
				array[$s-1]=$max
			fi

                        #echo "更新的阈值为：${array[@]}"

                        #echo "cpu-$core_index finish!"

                 else
                        echo "cpu-$core_index未达到更新的cpu阈值！"


                 fi
      	 else

                 echo "cpu-$core_index未达到cpu阈值！"

         fi

         #if [ $long -ge $run_time ]
         #then
         #	exit
         #fi
}

function main(){

	explain_json
	init_array
	array_max=100

	first_time=$(date +%s)
	end_time=$((first_time + total_time * 60))
	
	echo "starting..."
	sleep $start_time
	
	while [ $(date +%s) -lt $end_time ]
        do
		x=1
		s=1
		for((i=0; i<$number; i++))
		do
			mode=$(echo "$json_data" | jq -r ".monitor_$x.mode")	

			case $mode in
			"process_monitor")
				
				#echo "Be parsing..."
				#sleep 2

				get_json_base_data

				#echo "starting..."
				#sleep $start_time

				#first_time=$(date +%s)
				#end_time=$((first_time + total_time * 60))

				#while [ $(date +%s) -lt $end_time ]
				#do
				#s=1
				echo "__________________________________________________________________"
				echo "__________________________________________________________________"

					#for((i=0; i<$number; i++))
					#do
				get_app_data_p

				        	#if [ $cpu_num == 28 ] || [ $cpu_num == 27 ]
				if [[ "$cpu" =~ ^[a-zA-Z]+$ ]]
				then
		                	echo "Fault! Changing method..."
		                	sleep 1
		                	FLAG_P
		        	fi

		        	get_p_perf_data

				        	#let long++

		        	echo "################################################################"

		        	let s++
				let x++
				#echo $s

				#done

				echo "__________________________________________________________________"
				echo "__________________________________________________________________"
				echo ' ** '
				echo '/||\'
				echo ' ][ '

				;;

			"thread_monitor")
				#echo "Be parsing..."
				#sleep 2

				get_json_base_data
				echo "main:$x"

				#echo "starting..."
				#sleep $start_time

				#first_time=$(date +%s)
				#end_time=$((first_time + total_time * 60))

				#while [ $(date +%s) -lt $end_time ]
				#do
					#s=1
				echo "__________________________________________________________________"
				echo "__________________________________________________________________"

					#for((i=0; i<$number; i++))
					#do
		        	get_app_data_t

				        	#if [ $cpu_num == 28 ] || [ $cpu_num == 27 ]
		        	if [[ "$cpu" =~ ^[a-zA-Z]+$ ]]
				then
		                	echo "Fault! Changing method..."
		                	sleep 1
		                	FLAG_T
		        	fi
			

		        	get_t_perf_data

				        	#let long+=2

		        	#echo "################################################################"

		        	let s++
				let x++
				#echo $x

					#done

				echo "__________________________________________________________________"
				echo "__________________________________________________________________"
				echo ' ** '
				echo '/||\'
				echo ' ][ '

				;;

			"cpu_value_monitor")
				
				#echo "Be parsing..."
				#sleep 2

				get_json_base_data
				json_data=$(cat $"$js_name".json)
        			#mode=$(echo "$json_data" | jq -r ".monitor_$x.mode")
        			core_index=$(echo "$json_data" | jq -r ".monitor_$x.core_index")
				cpu_value=$(echo "$json_data" | jq -r ".monitor_$x.cpu_value")				
				#echo "starting..."
				#sleep $start_time

				#first_time=$(date +%s)
				#end_time=$((first_time + total_time * 60))

				#while [ $(date +%s) -lt $end_time ]
				#do
				#s=1
				echo "__________________________________________________________________"
				echo "__________________________________________________________________"
				
				cpu_value_idle=$(top -b -d 2 -1 -n 1 | grep -w "Cpu${core_index}" | awk -F [id] '{print $2}' | awk -F [,] '{print $2}')
				echo "cpu_${core_index}_idle: $cpu_value_idle"				
				cpu_value_idle_int=$(echo "scale=0; $cpu_value_idle / 1" | bc)				
				cpu_value_num=`expr 100 - $cpu_value_idle_int`				
				echo "cpu_${core_index}_usage: $cpu_value_num"

		        	get_cpu_perf_data

				        	#let long++

		        	#echo "################################################################"

		        	let s++
				let x++
				#echo $s

				#done

				echo "__________________________________________________________________"
				echo "__________________________________________________________________"
				echo ' ** '
				echo '/||\'
				echo ' ][ '

				;;


			"cpu_time_monitor")
				echo "Be parsing..."
				sleep 2
				
				explain_json_cpu
				#core_index=$(echo "$json_data" | jq -r '.core_index')
				echo "core_index = $core_index"
				start_time=$(echo "$json_data" | jq -r ".monitor_$x.start_time")
				echo "start time: $start_time(s)"
				
				calculate_moments
				
				echo "starting..."
				sleep $start_time

				paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
				echo "perf_event_paranoid: $paranoid"
				restrict=$(cat /proc/sys/kernel/kptr_restrict)
				echo "kptr_restrict: $restrict"
			
				if [ $paranoid == "-1" ]
				then
					echo "Unrestricted!"
				else
					echo -1 > /proc/sys/kernel/perf_event_paranoid
					echo 0 > /proc/sys/kernel/kptr_restrict
					paraniod=$(cat /proc/sys/kernel/perf_event_paranoid)
					echo "perf_event_paraniod: $paraniod"
					restrict=$(cat /proc/sys/kernel/kptr_restrict)
					echo "kptr_restrict: $restrict" 

				fi

				stop_tag=0

				while true
				do
					#current_time=$(date +%T)
					#echo "current_time = $current_time"
			
					#if [ $current_time != $issue_time ]
					#then
					#	echo "current_time = $current_time"
					#	echo "issue_time =  $issue_time"
					#elif [ $current_time = $issue_time ]
					#then
					#	sudo perf record -F 499 -C $core_num -o cpu_${core_num}_${issue_time}.data -g -- sleep 5
					#	sudo perf script -i cpu_${core_num}_${issue_time}.data > cpu_${core_num}_${issue_time}.unfold
						
					#	echo 3 > /proc/sys/kernel/perf_event_paranoid
					#	echo 1 > /proc/sys/kernel/kptr_restrict
					#	paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
					#	echo "perf_event_paranoid: $paranoid"
					#	restrict=$(cat /proc/sys/kernel/kptr_restrict)
					#	echo "kptr_restrict: $restrict"
						
					#	exit
					#fi
					
					index=0
				
					for ((i=0;i<count;i++))
					do

					        current_time=$(date +%T)
					        #echo $current_time
				        	if [ ${issue_time[$index]} = $current_time ]
				        	then
				                	echo $current_time
				                	echo ${issue_time[$index]}
				                	#echo "抓取"
							sudo /home/mazu/perf record -F 499 -C $core_index -o cpu_${core_index}_${issue_time[$index]}.data -g -- sleep 3
				        	        sudo /home/mazu/perf script -i cpu_${core_index}_${issue_time[$index]}.data > cpu_${core_index}_${issue_time[$index]}.unfold
							let stop_tag++

				        	fi
				        	let index++
					done
					if [ $stop_tag == $count ]
					then
						echo 3 > /proc/sys/kernel/perf_event_paranoid
				                echo 1 > /proc/sys/kernel/kptr_restrict
				                paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
				                echo "perf_event_paranoid: $paranoid"
				                restrict=$(cat /proc/sys/kernel/kptr_restrict)
				                echo "kptr_restrict: $restrict"

						#exit
					fi

					sleep 1

				done

				;;

			esac
		done
	done
}



FLAG_P() {
		echo "Successfully!"

        	datetime=$(date +%H:%M:%S)
        	echo ${datetime}

		first_time=$(date +%s)
		end_time=$((first_time + total_time * 60))

		while [ $(date +%s) -lt $end_time ]
        	do
			s=1
			x=1
                	echo "__________________________________________________________________"
                	echo "__________________________________________________________________"

                	for((i=0; i<$number; i++))
                	do

                        	json_data=$(cat $"$js_name".json)

                        	echo "################################################################"

                        	datetime=$(date +%H:%M:%S)
                        	echo ${datetime}

                        	app_name=$(echo "$json_data" | jq -r ".monitor_$x.app_name")
                        	#echo "$(top -b -d 2 -n 1 | grep "$app_name")"
                        	echo "app_name: $app_name"

                        	soc_name=$(echo "$json_data" | jq -r ".monitor_$x.soc")
                        	echo "soc_name: $soc_name"

                        	threshold=$(echo "$json_data" | jq -r ".monitor_$x.threshold_${app_name}")
                        	echo "threshold_$app_name: $threshold"

				pid_num=$(get_pid)
                                echo ">>>>>>>>>>>>pid: "$pid_num

                        	echo "----- ----- -----"

				echo "file task pid:$pid_num"

				tmp=$(top -b -d 2 -n 1 -p $pid_num | tail -n 1)
				tmp_top=$(top -b -d 2 -n 1 -p $pid_num)
         			echo "top信息：$tmp"
         			if [ -z "$tmp" ]
         			then
                 			echo "原始top信息，tmp_top：$tmp_top"
         			fi

				task_name=$(echo $tmp | awk '{print $13}' )
                        	echo "file task_name:$task_name"

                        	cpu_usage=$(echo $tmp | awk '{print $10}' )
                        	echo "file task cpu usage:$cpu_usage"

                        	cpu=$cpu_usage

                        	echo "$cpu"
                        	cpu_num=$(echo "scale=0; $cpu / 1" | bc)
                        	echo "cpu占用率为：$cpu_num"

                        	echo "----- ----- -----"

				get_p_perf_data
                        	
                        	#let long++

                        	#echo "################################################################"

                        	let s++
				let x++


                	done

                	echo "__________________________________________________________________"
                	echo "__________________________________________________________________"
                	echo ' **  '
                	echo '/||\ '
                	echo ' ][  '

        	done


        }



FLAG_T() {

		echo "Successfully!"

                datetime=$(date +%H:%M:%S)
                echo ${datetime}

		first_time=$(date +%s)
		end_time=$((first_time + total_time * 60))

		while [ $(date +%s) -lt $end_time ]      
                do
                        s=1
			x=1
                        echo "__________________________________________________________________"
                        echo "__________________________________________________________________"

                        for((i=0; i<$number; i++))
                        do
                                json_data=$(cat $"$js_name".json)

                                echo "################################################################"

                                datetime=$(date +%H:%M:%S)
                                echo ${datetime}

                                app_name=$(echo "$json_data" | jq -r ".monitor_$x.app_name")
                                #echo "$(top -b -d 1 -n 1 | grep "$app_name")"
                                echo "app_name: $app_name"

				thread_name=$(echo "$json_data" | jq -r ".monitor_$x.thread_name")
	 			echo "thread_name: $thread_name"

                                soc_name=$(echo "$json_data" | jq -r ".monitor_$x.soc")
                        	echo "soc_name: $soc_name"

                                threshold=$(echo "$json_data" | jq -r ".monitor_$x.threshold_${thread_name}")
                                echo "threshold_$thread_name: $threshold"

				tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
                                echo ">>>>>>>>>>>>tid: "$tid_num
	 			
				if [ -z "$tid_num" ]
				then						
	 				echo "重新获取tid"
					tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $1}')
					echo ">>>>>>>>>>>>tid: "$tid_num
						
					if [ -n "$tid_num"]
					then
						echo "get tid successfully"
					fi

					echo "再次获取/确认tid"
	 				tid_num=$(ps -T -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
	 				echo ">>>>>>>>>>>>tid: "$tid_num
				fi

				if [ -z "$tid_num"]
				then
					echo "该线程$thread_name未被拉起"
                              
				echo "----- ----- -----"

				else

                                	echo "file task pid:$tid_num"

					tmp=$(top -b -H -d 2 -n 1 | grep "$tid_num")
					echo "$tmp"

					task_name=$(echo $tmp | awk '{print $13}' )
                                	echo "file task_name:$task_name"

                                	cpu_usage=$(echo $tmp | awk '{print $10}' )
                                	echo "file task cpu usage:$cpu_usage"

                                	cpu=$cpu_usage

                                	echo "$cpu"
                                	cpu_num=$(echo "scale=0; $cpu / 1" | bc)
                                	echo "cpu占用率为：$cpu_num"
				fi

                                echo "----- ----- -----"

				get_t_perf_data

                                #let long+=2

                                #echo "################################################################"

                                let s++
				let x++


                        done

                        echo "__________________________________________________________________"
                        echo "__________________________________________________________________"
                        echo ' ** '
                        echo '/||\'
                        echo ' ][ '

                done
	}


echo "Monitor status: Running..."

main | tee -a perf_monitor_plus.log


