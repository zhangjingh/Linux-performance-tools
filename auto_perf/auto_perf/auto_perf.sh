#!/bin/bash

function is_restrict(){
	datetime=$(date +%Y_%m_%d_%T)
	log_timestamp=$datetime
	echo "[$datetime] Checking & Starting..." |tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log

	paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
	echo "perf_event_paranoid: $paranoid" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
	restrict=$(cat /proc/sys/kernel/kptr_restrict)
	echo "kptr_restrict: $restrict" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
	
	if [ $paranoid == "-1" ]
	then
		echo "Unrestricted!"
	else
		datetime=$(date +%Y_%m_%d_%T)
		echo "[$datetime] Lifting restrictions..." | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
	
		echo -1 > /proc/sys/kernel/perf_event_paranoid
        	echo 0 > /proc/sys/kernel/kptr_restrict
		paraniod=$(cat /proc/sys/kernel/perf_event_paranoid)
        	echo "perf_event_paraniod: $paraniod" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
        	restrict=$(cat /proc/sys/kernel/kptr_restrict)
        	echo "kptr_restrict: $restrict" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log

	fi
	echo "****************************************************************" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
}

function restrict(){
	datetime=$(date +%Y_%m_%d_%T)
	echo "[$datetime] Closing ..." | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
	echo 3 > /proc/sys/kernel/perf_event_paranoid
	echo 1 > /proc/sys/kernel/kptr_restrict
	paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
        echo "perf_event_paranoid: $paranoid" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
        restrict=$(cat /proc/sys/kernel/kptr_restrict)
        echo "kptr_restrict: $restrict" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log

	echo "****************************************************************" | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
}

function get_uuid(){
	version | grep UUID >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
	echo "****************************************************************" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
}

function get_pidstat_info(){
	pidstat >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
	echo "****************************************************************" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
}

function get_cgroup_quotas(){
	datetime=$(date +%Y_%m_%d_%T)
	echo "[$datetime] Getting cgroup_quotas information..."
	cp /home/mazu/app/conf/resource_quotas/s1_cgconfig.conf ./nio_perf_data
	cp /home/mazu/app/conf/resource_quotas/s2_cgconfig.conf ./nio_perf_data
	cp /home/mazu/app/conf/resource_quotas/s3_cgconfig.conf ./nio_perf_data
	cp /home/mazu/app/conf/resource_quotas/s4_cgconfig.conf ./nio_perf_data
	echo "Finish"
}

function get_cgroup_restrict(){
	datetime=$(date +%Y_%m_%d_%T)
        echo "[$datetime] Getting cgroup_restrict information..."
	cp /mnt/ramdisk/logs/ouread_cgstat.INFO ./nio_perf_data
	echo "Finish"
}

function run(){
        datetime=$(date +%Y_%m_%d_%T)
        #file_time=$datetime
        mkdir nio_perf_data

        echo "正在启动和准备数据......"
        
        #通用必要信息
        is_restrict
        get_uuid
        get_pidstat_info
        get_cgroup_quotas
        get_cgroup_restrict

}

function get_perf(){
	while getopts ':p:c:afh' opt
	do

        	case $opt in
                	p)     
				run

				#抓取指定进程perf数据
				echo "nio_perf -p $2"
				start_time=$(date +%Y_%m_%d_%T)
				echo "[$start_time] Getting process perf data..." >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log 
                       
                        	sudo perf record -F 499 -p $2 -o process_$2_${start_time}.data -g -- sleep 5
                        	sudo perf script -i process_$2_${start_time}.data > process_$2_${start_time}.unfold
				sudo chmod 777 process_*

				mv process_* ./nio_perf_data

				end_time=$(date +%Y_%m_%d_%T)
				echo "[$end_time] Complete process perf data" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log

				restrict
				echo "****************************************************************" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
				;;
                	c)
				run

				#抓取指定cpu的perf数据
                        	echo "nio_perf -c $2"
				start_time=$(date +%Y_%m_%d_%T)
				echo "[$start_time] Getting cpu perf data..." >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
                        	
				sudo perf record -F 499 -C $2 -o cpu_$2_${start_time}.data -g -- sleep 5
                                sudo perf script -i cpu_$2_${start_time}.data > cpu_$2_${start_time}.unfold
				sudo chmod 777 cpu_*

				mv cpu_* ./nio_perf_data

				end_time=$(date +%Y_%m_%d_%T)
                                echo "[$end_time] Complete cpu perf data" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
				
				restrict
				echo "****************************************************************" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
				;;
			a)
				run

				#自动化监控进程/线程perf
				function explain_json(){
					js_name="auto_monitor"

					json_data=$(cat $"$js_name".json)
					mode=$(echo "$json_data" | jq -r '.mode_p_or_t')

					json_data=$(cat $"$js_name".json)
					number=$(echo "$json_data" | jq -r '.number')

					echo "you want to monitor: $mode"
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
					number=$(echo "$json_data" | jq -r '.number')

					echo "the number of apps is: $number"

					#flag=0
					#cpu_tmp=0
					s=1

					start_time=$(echo "$json_data" | jq -r ".start_time")
					echo "start time: ${start_time}s"

					total_time=$(echo "$json_data" | jq -r ".total_time")
					echo "total_time: ${total_time}min"

					step=$(echo "$json_data" | jq -r ".step")
					echo "step: $step"

					frequency=$(echo "$json_data" | jq -r ".frequency")
					echo "frequency: $frequency"

					sample_time=$(echo "$json_data" | jq -r ".sample_time")
					echo "sample_time: ${sample_time}s"

					#long=0
					#run_time=`expr $total_time \* 60`

					datetime=$(date +%H:%M:%S)
					echo ${datetime}
				}

				function get_app_data_p(){
					 json_data=$(cat $"$js_name".json)

					 echo "################################################################"

					 datetime=$(date +%H:%M:%S)
					 echo ${datetime}

					 app_name=$(echo "$json_data" | jq -r ".app_$s")
					 echo "app_name: $app_name"

					 soc_name=$(echo "$json_data" | jq -r ".soc")
					 echo "soc_name: $soc_name"

					 threshold=$(echo "$json_data" | jq -r ".threshold_${app_name}")
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

					 echo "################################################################"
							
					 datetime=$(date +%H:%M:%S)
					 echo ${datetime}

					 app_name=$(echo "$json_data" | jq -r ".app_$s")
					 echo "app_name: $app_name"

					 thread_name=$(echo "$json_data" | jq -r ".thread_$s")
					 echo "thread_name: $thread_name"

					 threshold=$(echo "$json_data"  | jq -r ".threshold_${thread_name}")
					 echo "threshold_$thread_name: $threshold"

					 soc_name=$(echo "$json_data" | jq -r ".soc")
					 echo "soc_name: $soc_name"

					 tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $1}')
					 echo ">>>>>>>>>>>>tid: "$tid_num
					 while [ -z "$tid_num" ]
	 				 do
		 				 echo "重新获取tid"
						 tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
					 	 echo ">>>>>>>>>>>>tid: "$tid_num

					 	 echo "再次获取tid"
	 					 tid_num=$(ps -T -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
	 					 echo ">>>>>>>>>>>>tid: "$tid_num
	 				 done

					 echo "----- ----- -----"

					 echo "file task tid:$tid_num"

					 tmp=$(top -b -H -d 2 -n 1 | grep "$tid_num")
					 echo "$tmp"

					 task_name=$(echo $tmp | awk '{print $12}' )
					 echo "file task_name:$task_name"

					 cpu_usage=$(echo $tmp | awk '{print $9}' )
					 echo "file task cpu usage:$cpu_usage"

					 cpu=$cpu_usage

					 echo "$cpu"
					 cpu_num=$(echo "scale=0; $cpu / 1" | bc)
					 echo "cpu占用率为：$cpu_num"

					 echo "----- ----- -----"
				}

				function get_p_perf_data(){
					 max=$threshold

					 if [ $cpu_num -gt $max ]
					 then
						if [ $cpu_num -gt ${array[$s-1]} ]
						then

							echo "OK! Start grasping..."

							perf record -F 499 -p $pid_num -o ${task_name}_${cpu_usage}_${datetime}.data -g -- sleep $sample_time
					       	        perf script -i ${task_name}_${cpu_usage}_${datetime}.data > ${task_name}_${cpu_usage}_${datetime}.unfold
							#~/app/FlameGraphe/stackcollapse-perf.pl ${task_name}_${datetime}.unfold > ${task_name}_${datetime}.folded
							#~/app/FlameGraph/flamegraph.pl ${task_name}_${datetime}.folded > ${task_name}_${cpu_usage}_${datetime}.svg

							echo "$(top -b -d 2 -n 1 -p $pid_num | tail -n 1)"

							mv ${task_name}_* ./nio_perf_data

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
					 max=$threshold

					 if [ $cpu_num -gt $max ]
					 then
						if [ $cpu_num -gt ${array[$s-1]} ]
						then

							echo "OK! Start grasping..."

							perf record -F "$frequency" -t "$tid_num" -o ${task_name}_${cpu_usage}_${datetime}_thread.data -g -- sleep "$sample_time"
							perf script -i ${task_name}_${cpu_usage}_${datetime}_thread.data > ${task_name}_${cpu_usage}_${datetime}_thread.unfold
							#~/app/FlameGraph/stackcollapse-perf.pl ${task_name}_${datetime}_thread.unfold > ${task_name}_${datetime}_thread.folded
							#~/app/FlameGraph/flamegraph.pl ${task_name}_${datetime}_thread.folded > ${task_name}_${pid}_${cpu_usage}_${datetime}_thread.svg
							
							echo "$(top -b -H -d 2 -n 1 | grep "$tid_num")"

							mv ${task_name}_* ./nio_perf_data

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

				function main(){
					explain_json
					init_array
					array_max=100

					case $mode in
					"p")

						echo "Be parsing..."
						sleep 3

						get_json_base_data

						echo "starting..."
						sleep $start_time
						
						first_time=$(date +%s)
						end_time=$((first_time + total_time * 60))

						while [ $(date +%s) -lt $end_time ]
						do
							s=1
							echo "__________________________________________________________________"
							echo "__________________________________________________________________"

							for((i=0; i<$number; i++))
							do
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

							done

							echo "__________________________________________________________________"
							echo "__________________________________________________________________"
							echo ' ** '
							echo '/||\'
							echo ' ][ '

						done

						;;

					"t")
						echo "Be parsing..."
						sleep 3

						get_json_base_data

						echo "starting..."
						sleep $start_time
						
						first_time=$(date +%s)
						end_time=$((first_time + total_time * 60))

						while [ $(date +%s) -lt $end_time ]
						do
							s=1
							echo "__________________________________________________________________"
							echo "__________________________________________________________________"

							for((i=0; i<$number; i++))
							do
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

								echo "################################################################"

								let s++

							done

							echo "__________________________________________________________________"
							echo "__________________________________________________________________"
							echo ' ** '
							echo '/||\'
							echo ' ][ '

						done

						;;
					esac
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
							echo "__________________________________________________________________"
							echo "__________________________________________________________________"

							for((i=0; i<$number; i++))
							do

								json_data=$(cat $"$js_name".json)

								echo "################################################################"

								datetime=$(date +%H:%M:%S)
								echo ${datetime}

								app_name=$(echo "$json_data" | jq -r ".app_$s")
								#echo "$(top -b -d 2 -n 1 | grep "$app_name")"
								echo "app_name: $app_name"

								soc_name=$(echo "$json_data" | jq -r ".soc")
								echo "soc_name: $soc_name"

								threshold=$(echo "$json_data" | jq -r ".threshold_${app_name}")
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

								echo "################################################################"

								let s++


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
							echo "__________________________________________________________________"
							echo "__________________________________________________________________"

							for((i=0; i<$number; i++))
							do
								json_data=$(cat $"$js_name".json)

								echo "################################################################"

								datetime=$(date +%H:%M:%S)
								echo ${datetime}

								app_name=$(echo "$json_data" | jq -r ".app_$s")
								#echo "$(top -b -d 2 -n 1 | grep "$app_name")"
								echo "app_name: $app_name"

								thread_name=$(echo "$json_data" | jq -r ".thread_$s")
					 			echo "thread_name: $thread_name"

								soc_name=$(echo "$json_data" | jq -r ".soc")
								echo "soc_name: $soc_name"

								threshold=$(echo "$json_data" | jq -r ".threshold_${thread_name}")
								echo "threshold_$thread_name: $threshold"

								tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
								echo ">>>>>>>>>>>>tid: "$tid_num
								while [ -z "$tid_num" ]
	 				 			do
		 				 			echo "重新获取tid"
						 			tid_num=$(top -b -H -n 1 -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $1}')
					 	 			echo ">>>>>>>>>>>>tid: "$tid_num

									echo "再次获取tid"
	 								tid_num=$(ps -T -p $(pidof ${app_name}) | grep ${thread_name} | awk '{print $2}')
	 								echo ">>>>>>>>>>>>tid: "$tid_num
	 				 			done

								echo "----- ----- -----"

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

								echo "----- ----- -----"

								get_t_perf_data

								#let long+=2

								echo "################################################################"

								let s++


							done

							echo "__________________________________________________________________"
							echo "__________________________________________________________________"
							echo ' ** '
							echo '/||\'
							echo ' ][ '

						done
					}


				echo "AUTO monitor status: Running..."
				sudo apt-get update
				sudo apt-get install -y jq
				main | tee -a ./nio_perf_data/nio_perf_data_${log_timestamp}.log
				sudo chmod 777 ./nio_perf_data/*.data ./nio_perf_data/*.unfold

				datetime=$(date +%Y_%m_%d_%T)
				echo "[$datetime] Complete AUTO monitor" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
				
				restrict
				echo "****************************************************************" >> ./nio_perf_data/nio_perf_data_${log_timestamp}.log
				;;
			f)
				#获取火焰图
				datetime=$(date +%Y_%m_%d_%T)
				echo "[$datetime] Get flamegraph..."
				
				is_restrict
				sudo chmod 777 ./nio_perf_data/*
				for file in $(ls ./nio_perf_data/*.data); 
				do
     				echo "find new perf record file ${file}";
     				perfname=${file%.data*};
     				echo "get perf core name:  ${perfname}";
     				#sudo /usr/bin/perf script -i ${perfname}.data > ${perfname}.unfold
     				#../stackcollapse-perf.pl  ${perfname}.unfold > ${perfname}.folded
     				#../flamegraph.pl   ${perfname}.folded > ${perfname}.svg

     				sudo perf script -i ${perfname}.data | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl > ${perfname}.svg
     				echo "generate new svg file ${perfname}.svg done!";
				done
				
				datetime=$(date +%Y_%m_%d_%T)
				echo "[$datetime] Finish generating flamegraph!"

				datetime=$(date +%Y_%m_%d_%T)
			        echo "[$datetime] Closing ..."
        			echo 3 > /proc/sys/kernel/perf_event_paranoid
        			echo 1 > /proc/sys/kernel/kptr_restrict
        			paranoid=$(cat /proc/sys/kernel/perf_event_paranoid)
        			echo "perf_event_paranoid: $paranoid"
        			restrict=$(cat /proc/sys/kernel/kptr_restrict)
        			echo "kptr_restrict: $restrict" 
				;;

			h)
				#帮助，使用说明
				echo "-------------------------------------------------------------------------------------------------------"
				echo "用法："
				echo "sudo ./nio_perf.sh [options] [parameters]"
				echo "                                         "
				echo "选项："
				echo "-h，--help		使用说明"
				echo " "
				echo "-p, --pid_perf<pid> 	抓取指定进程perf数据"
				echo " "
				echo "-c, --cpu_perf<cpu_num>	抓取指定cpu的perf数据"
				echo " "
				echo "-a, auto 不需要参数	自动监控并抓取指定进程/线程perf数据，使用前需要设置配置文件参数(auto_monitor.json)"
				echo " "
				echo "-f, flame 不需要参数	根据生成的perf数据生成火焰图"
				echo "-------------------------------------------------------------------------------------------------------"
				;;

        	esac
	done

}

get_perf $@





