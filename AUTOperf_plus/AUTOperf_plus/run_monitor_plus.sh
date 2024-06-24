#!/bin/bash

echo "Start!"
sleep 1

./monitor_plus.sh | tee perf_monitor_plus.log

echo "Finish!"
