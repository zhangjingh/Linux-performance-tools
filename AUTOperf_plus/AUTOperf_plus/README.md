1. JSON文件格式按照`monitor_plus.json`中的格式写，顺序不影响结果，
	* -`start_time`：工具启动时间，(s)
	* -`number`：监控进程或线程的总数量
	* -`mode`：监控模式选择，`process_monitor`，`thread_monitor`，`cpu_time_monitor`，`cpu_value_monitor`
	* -`soc`: 被监控进程/线程所在的SOC
	* -`app_name`：监控的app的名称
	* -`thread_name`：监控的线程名称
	* -`threshold_xxx`：所监控进程/线程的cpu阈值,“xxx”表示监控的进程或线程名称
	* -`issue_time`：在`cpu_time_monitor`模式下，指定抓取时间点
	* -`core_index`：cpu核的编号，指定监控哪个核
	* -`cpu_value`：`cpu_value_monitor`模式下，设置某个`core_index`的cpu占用率阈值
	* -`sample_time`：设置perf采样时间,(s)
	* -`total_time`：设置监控总时长,(min)
	* -`step`：设置阈值步长
	* -`frequency`：设置perf采样频率

2. 运行时注意: 
	* 该脚本使用“jq”解析JSON文件，运行前请安装jq，`sudo apt-get update`；`sudo apt-get install jq`；`sudo ./monitor_plus.sh`;
	*  需要将FlameGraph的路径更改到当前运行环境下正确路径，默认FlameGraph文件夹路径为：~/app/FlameGraph/;
	*  在`js_name`变量中正确修改JSON文件名，以便正确解析;
	*  jq不支持解析“-”，如监控的进程/线程名中有“-”（破折号），则取“-”前或后的word作为名称；
	      

3. 功能：
	1. 可自定义各个参数；
	2. 可解析JSON文件数据；
	3. 可对多个app配置参数进行监控；
	4. 单个core的多个时间点监控并对指定时间点cpu进行perf数据抓取；
	5. 多个core的阈值监控并对超限core进行抓取；
	6. 进程、线程、CPU均可监控，且可同时监控进程和线程；
	7. 根据step值，自动更新对应app的cpu阈值；
	8. 自动抓取超过设置阈值app的perf数据，自动生成unfold文件

4. 说明：
	1. 使用对“单个core的多个时间点监控并抓取”功能时，请只写一个"monitor"项；
	2. `core_index`和`issue_time`只在两种cpu监控模式下起作用；
	3. 该脚本适用所有pid格式的情况，无论打印的top数据中所监控的进程线程pid格式是否“顶格”或存在“空格”（保证整体格式统一即可），均可正确有效监控；
	4. 解析JSON文件数据时，要求JSON数据格式严格依照`monitor_plus.json`格式，内容顺序不会影响结果；
	5. 配置文件中只需要给定进程/线程名称即可自动获取pid,tid；
	6. 进行CPU监控时，指定时间点设置最多指定5个时间点，请按时间递增顺序一次补充进数组中，不足5个就写空""；
	7. 使用该脚本监控进程和线程时，监控数量不限，只需配置JSON文件即可。
  


