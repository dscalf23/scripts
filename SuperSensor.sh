#!/bin/bash
#
#Izoox.com
#David Scalf 
#Izoox Super Sensor v1.0
#Used for gathering Memory, CPU, and HDD data for PRTG
#
#

declare -a MEMORY
declare -a PROCESSOR
declare -a HARDDISK
function ram {
	MEMTOTAL=$(awk '( $1 == "MemTotal:" ) { print $2/1024 }' /proc/meminfo)
	MEMAVAILABLE=$(awk '( $1 == "MemAvailable:" ) { print $2/1024 }' /proc/meminfo)
	SWAPTOTAL=$(awk '( $1 == "SwapTotal:" ) { print $2/1024 }' /proc/meminfo)
	SWAPFREE=$(awk '( $1 == "SwapFree:" ) { print $2/1024 }' /proc/meminfo)
	MEMPERCENT=$(awk -v a="$MEMAVAILABLE" -v b="$MEMTOTAL" 'BEGIN{print ( a * 100 ) / b }')
	if [ $SWAPTOTAL = 0 ]; then
		SWAPPERCENT=100
	else
		SWAPPERCENT=$(awk -v a="$SWAPFREE" -v b="$SWAPTOTAL" 'BEGIN{print ( a * 100 ) / b }')
	fi

	MEMORY=($MEMTOTAL $MEMAVAILABLE $MEMPERCENT $SWAPTOTAL $SWAPFREE $SWAPPERCENT)
}
function cpu {
	rm -f /tmp/topCPU.log
	top -b -n 1 >> /tmp/topCPU.log
	CPUCORES=$(cat /proc/cpuinfo | cat | grep ^processor | wc -l)
	CPU1MIN=$(grep -w "top -" /tmp/topCPU.log | sed -n 's/^.*e://p' | sed 's/[[:blank:]]//g' | awk -F, '{ print $1 }')
	CPU5MIN=$(grep -w "top -" /tmp/topCPU.log | sed -n 's/^.*e://p' | sed 's/[[:blank:]]//g' | awk -F, '{ print $2 }')
	CPU15MIN=$(grep -w "top -" /tmp/topCPU.log | sed -n 's/^.*e://p' | sed 's/[[:blank:]]//g' | awk -F, '{ print $3 }')
	CPUPER1M=$(awk -v a="$CPU1MIN" -v b="$CPUCORES" 'BEGIN{print ( a * 100 ) / b }')
	CPUPER5M=$(awk -v a="$CPU5MIN" -v b="$CPUCORES" 'BEGIN{print ( a * 100 ) / b }')
	CPUPER15M=$(awk -v a="$CPU15MIN" -v b="$CPUCORES" 'BEGIN{print ( a * 100 ) / b }')
	CPUUS=$(grep -w "%Cpu(s):" /tmp/topCPU.log | sed -n 's/^.*)://p' | sed 's/[[:blank:]]//g' | tr -d [a-z] | awk -F, '{ print $1 }')
	CPUSY=$(grep -w "%Cpu(s):" /tmp/topCPU.log | sed -n 's/^.*)://p' | sed 's/[[:blank:]]//g' | tr -d [a-z] | awk -F, '{ print $2 }')
	CPUID=$(grep -w "%Cpu(s):" /tmp/topCPU.log | sed -n 's/^.*)://p' | sed 's/[[:blank:]]//g' | tr -d [a-z] | awk -F, '{ print $4 }')

	PROCESSOR=($CPUCORES $CPU1MIN $CPUPER1M $CPU5MIN $CPUPER5M $CPU15MIN $CPUPER15M $CPUUS $CPUSY $CPUID)
}
function hdd {
	HDDTOTAL=$(df -T | awk '( $7 == "/" ) { print $3/1000000 }')
	HDDAVAILABLE=$(df -T | awk '( $7 == "/" ) { print $5/1000000 }')
	HDDPERCENT=$(df -T | sed 's/\%//g' | awk '( $7 == "/" ) { print $6 }')

	HARDDISK=($HDDTOTAL $HDDAVAILABLE $HDDPERCENT)

}
function json {
	ram
	cpu
	hdd
	CHANNELS='{
          "prtg": {
           "result": [
            {
             "channel": "Total Memory",
             "value": "'${MEMORY[0]}'",
	     "float": "1",
	     "customunit": "MB"
            },
            {
             "channel": "Available Memory",
             "value": "'${MEMORY[1]}'",
	     "float": "1",
	     "customunit": "MB"
            },
	    {
             "channel": "Free Memory %",
             "value": "'${MEMORY[2]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitminwarning": "20",
	     "limitminerror": "10",
	     "limitmode": "1"
            },
	    {
             "channel": "Total Swap",
             "value": "'${MEMORY[3]}'",
	     "float": "1",
	     "customunit": "MB"
            },
	    {
             "channel": "Available Swap",
             "value": "'${MEMORY[4]}'",
	     "float": "1",
	     "customunit": "MB"
            },
	    {
             "channel": "Free Swap %",
             "value": "'${MEMORY[5]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitminwarning": "99",
	     "limitminerror": "90",
	     "limitmode": "1"
            },
	    {
             "channel": "CPU Cores",
             "value": "'${PROCESSOR[0]}'",
	     "customunit": "Core(s)"
            },
	    {
             "channel": "CPU 1M Load Average",
             "value": "'${PROCESSOR[1]}'",
	     "float": "1"
            },
	    {
             "channel": "CPU 1M Load %",
             "value": "'${PROCESSOR[2]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitmaxwarning": "90",
	     "limitmode": "1"
            },
	    {
             "channel": "CPU 5M Load Average",
             "value": "'${PROCESSOR[3]}'",
	     "float": "1"
            },
	    {
             "channel": "CPU 5M Load %",
             "value": "'${PROCESSOR[4]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitmaxwarning": "75",
	     "limitmode": "1"
            },
	    {
             "channel": "CPU 15M Load Average",
             "value": "'${PROCESSOR[5]}'",
	     "float": "1"
            },
	    {
             "channel": "CPU 15M Load %",
             "value": "'${PROCESSOR[6]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitmaxwarning": "30",
	     "limitmaxerror": "50",
	     "limitmode": "1"
            },
	    {
             "channel": "CPU Usage User",
             "value": "'${PROCESSOR[7]}'",
	     "float": "1",
	     "customunit": "%"
            },
	    {
             "channel": "CPU Usage System",
             "value": "'${PROCESSOR[8]}'",
	     "float": "1",
	     "customunit": "%"
            },
	    {
             "channel": "CPU Idle",
             "value": "'${PROCESSOR[9]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitminwarning": "50",
	     "limitmode": "1"
            },
	    {
             "channel": "Disk Total",
             "value": "'${HARDDISK[0]}'",
	     "float": "1",
	     "customunit": "GB"
            },
	    {
             "channel": "Disk Free",
             "value": "'${HARDDISK[1]}'",
	     "float": "1",
	     "customunit": "GB"
            },
	    {
             "channel": "Disk Used %",
             "value": "'${HARDDISK[2]}'",
	     "float": "1",
	     "customunit": "%",
	     "limitmaxwarning": "75",
	     "limitmaxerror": "90",
	     "limitmode": "1"
            }
           ]
          }
         }'
echo $CHANNELS
}
json
