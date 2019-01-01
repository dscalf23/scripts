#!/bin/bash
#
#Izoox.com
#David Scalf 
#Izoox Super Sensor v1.1
#Used for gathering Memory, CPU, and HDD data for PRTG
#
#

declare DDR
declare AMD
declare -a SSD
function ram {
	rm -f /tmp/MEM.txt
	cat /proc/meminfo >> /tmp/MEM.txt
	MEMTOTAL=$(awk '( $1 == "MemTotal:" ) { print $2/1024 }' /tmp/MEM.txt)
	MEMAVAILABLE=$(awk '( $1 == "MemAvailable:" ) { print $2/1024 }' /tmp/MEM.txt)
	SWAPTOTAL=$(awk '( $1 == "SwapTotal:" ) { print $2/1024 }' /tmp/MEM.txt)
	SWAPFREE=$(awk '( $1 == "SwapFree:" ) { print $2/1024 }' /tmp/MEM.txt)
	MEMPERCENT=$(awk -v a="$MEMAVAILABLE" -v b="$MEMTOTAL" 'BEGIN{print ( a * 100 ) / b }')
	if [ $SWAPTOTAL = 0 ]; then
		SWAPPERCENT=100
	else
		SWAPPERCENT=$(awk -v a="$SWAPFREE" -v b="$SWAPTOTAL" 'BEGIN{print ( a * 100 ) / b }')
	fi

	MEMORY=($MEMTOTAL $MEMAVAILABLE $MEMPERCENT $SWAPTOTAL $SWAPFREE $SWAPPERCENT)
	DDR='{
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
			"limitminwarning": "90",
			"limitminerror": "60",
			"limitmode": "1"
		},'
}
function cpu {
	rm -f /tmp/CPU.txt
	top -b -n 1 >> /tmp/CPU.txt
	CPUCORES=$(cat /proc/cpuinfo | cat | grep ^processor | wc -l)
	CPU1MIN=$(grep -w "top -" /tmp/CPU.txt | sed -n 's/^.*e://p' | sed 's/[[:blank:]]//g' | awk -F, '{ print $1 }')
	CPU5MIN=$(grep -w "top -" /tmp/CPU.txt | sed -n 's/^.*e://p' | sed 's/[[:blank:]]//g' | awk -F, '{ print $2 }')
	CPU15MIN=$(grep -w "top -" /tmp/CPU.txt | sed -n 's/^.*e://p' | sed 's/[[:blank:]]//g' | awk -F, '{ print $3 }')
	CPUPER1M=$(awk -v a="$CPU1MIN" -v b="$CPUCORES" 'BEGIN{print ( a * 100 ) / b }')
	CPUPER5M=$(awk -v a="$CPU5MIN" -v b="$CPUCORES" 'BEGIN{print ( a * 100 ) / b }')
	CPUPER15M=$(awk -v a="$CPU15MIN" -v b="$CPUCORES" 'BEGIN{print ( a * 100 ) / b }')
	CPUUS=$(grep -w "%Cpu(s):" /tmp/CPU.txt | sed -n 's/^.*)://p' | sed 's/[[:blank:]]//g' | tr -d [a-z] | awk -F, '{ print $1 }')
	CPUSY=$(grep -w "%Cpu(s):" /tmp/CPU.txt | sed -n 's/^.*)://p' | sed 's/[[:blank:]]//g' | tr -d [a-z] | awk -F, '{ print $2 }')
	CPUID=$(grep -w "%Cpu(s):" /tmp/CPU.txt | sed -n 's/^.*)://p' | sed 's/[[:blank:]]//g' | tr -d [a-z] | awk -F, '{ print $4 }')

	PROCESSOR=($CPUCORES $CPU1MIN $CPUPER1M $CPU5MIN $CPUPER5M $CPU15MIN $CPUPER15M $CPUUS $CPUSY $CPUID)
	AMD='{
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
	},'
}
function hdd {
	rm -f /tmp/HDD.txt
	df | grep ^/dev | cat -n >> /tmp/HDD.txt
	HDDCOUNT=$(cat /tmp/HDD.txt | wc -l)
	i=1
	while [ $i -le $HDDCOUNT ]
	do
		HDDNAME=$(awk -v C="$i" '( $1 == C ) { print $2 }' /tmp/HDD.txt)
		HDDTOTAL=$(awk -v C="$i" '( $1 == C ) { print $3/1000000 }' /tmp/HDD.txt)
		HDDAVAILABLE=$(awk -v C="$i" '( $1 == C ) { print $5/1000000 }' /tmp/HDD.txt)
		HDDPERCENT=$(awk -v C="$i" '( $1 == C ) { print $6 }' /tmp/HDD.txt | sed 's/\%//g')
		if [ $i -lt $HDDCOUNT ]; then
			END='},'
		else
			END='}'
		fi
		n=($i-1)
		SSD[$n]='{
			"channel": "Disk Total ('${HDDNAME}')",
			"value": "'${HDDTOTAL}'",
			"float": "1",
			"customunit": "GB"
		},
		{
			"channel": "Disk Free ('${HDDNAME}')",
			"value": "'${HDDAVAILABLE}'",
			"float": "1",
			"customunit": "GB"
		},
		{
			"channel": "Disk Used % ('${HDDNAME}')",
			"value": "'${HDDPERCENT}'",
			"float": "1",
			"customunit": "%",
			"limitmaxwarning": "75",
			"limitmaxerror": "90",
			"limitmode": "1"
		'${END}''
		((i++))
	done


	#HARDDISK=($HDDTOTAL $HDDAVAILABLE $HDDPERCENT)

}
function json {
	ram
	cpu
	hdd
	CHANNELS='{
		"prtg": {
			"result": [
				'${DDR}'
				'${AMD}'
				'${SSD[@]}'
			]
		}
	}'
echo $CHANNELS
}
json
