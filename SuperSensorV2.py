#!/usr/bin/env python
## Izoox SuperSenor V2
## David Scalf
## 2019
##
## Rewrite in python using psutil for cross platform compatibility.

#Imports
import psutil
import os
import platform
import sys
import json

#Divisors/Constants
gB = float(1073741824.0)
mB = float(1048576.0)
kB = float(1024.0)

#Global Variables
osInfo = platform.system()

#CPU Stats
def getCPU():
    cpuCores = psutil.cpu_count(logical=True)
    cpuTime = psutil.cpu_times_percent(interval=1, percpu=False)
    #Output Section
    cpuOut = [{'channel':'CPU Cores','value':cpuCores,'customunit':'Core(s)'},
              {'channel':'CPU Usage System','value':cpuTime.system,'float':'1','customunit':'%'},
              {'channel':'CPU Usage User','value':cpuTime.user,'float':'1','customunit':'%'},
              {'channel': 'CPU Idle','value':cpuTime.idle,'float': '1','customunit': '%'}]
    #Linux Only CPU Info
    if osInfo != "Windows":
        cpuLoad = os.getloadavg()
        cpuAvg = {}
        for counter, value in enumerate(cpuLoad):
            cpuAvg[counter] = round((float(value)/cpuCores)*100, 2)
        loadOut = [{'channel':'CPU 1M Load %','value':cpuAvg[0],'float':'1','customunit':'%','limitmaxwarning':'100','limitmode':'1'},
                   {'channel':'CPU 5M Load %','value':cpuAvg[1],'float':'1','customunit':'%','limitmaxwarning':'85','limitmaxerror':'100','limitmode':'1'},
                   {'channel':'CPU 15M Load %','value':cpuAvg[2],'float':'1','customunit':'%','limitmaxwarning':'75','limitmaxerror':'90','limitmode':'1'}]
        cpuOut = cpuOut + loadOut
    return cpuOut

#Memory Stats
def getMEM():
    mem = psutil.virtual_memory()
    memTotal = round((mem.total/gB), 2)
    if memTotal > 0:
        memFree = round((mem.available / gB), 2)
        if osInfo == "Linux":
            memCached = round((mem.cached / gB), 2)
            memUsed = round((memTotal - (memFree + memCached)), 2)
        else:
            memUsed = round((memTotal - memFree), 2)
        # Output Section
        memOut = [{'channel': 'Total Ram', 'value': memTotal, 'float': '1', 'customunit': 'GB'},
                  {'channel': 'Free Ram', 'value': memFree, 'float': '1', 'customunit': 'GB'},
                  {'channel': 'Memory Utilization %', 'value': round(((memUsed / memTotal) * 100), 2), 'float': '1',
                   'customunit': '%', 'limitmaxwarning': '85', 'limitmaxerror': '95', 'limitmode': '1'}]

    #Swappieness
    swap = psutil.swap_memory()
    swapTotal = round((swap.total/gB), 2)
    if swapTotal > 0:
        swapUsed = round((swap.used/gB), 2)
        swapFree = round((swapTotal-swapUsed), 2)
        #Output Section
        swapOut = [{'channel':'Total Swap','value':swapTotal,'float':'1','customunit':'GB'},
                   {'channel':'Free Swap','value':swapFree,'float':'1','customunit':'GB'},
                   {'channel':'Swap Utilization %','value':round(((swapUsed/swapTotal)*100), 2),'float':'1','customunit':'%','limitmaxwarning':'30','limitmaxerror':'50','limitmode':'1'}]
        memOut = memOut + swapOut
        return memOut
    else:
        return memOut

#Network Stats
def getNET():
    net = psutil.net_io_counters(pernic=False)
    netDrop = net.dropin+net.dropout
    #Output Section
    netOut = [{'channel':'Network Sent','value':round((net.bytes_sent/kB), 2),'float':'1','customunit':'GB'},
               {'channel':'Network Received','value':round((net.bytes_recv/kB), 2),'float':'1','customunit':'GB'},
               {'channel':'Packets Dropped','value':netDrop,'customunit':'#'}]
    return netOut

#Disk Stats
def getDISK():
    disks = psutil.disk_partitions(all=False)
    diskOut = []
    #Disk Utilization
    for counter, value in enumerate(disks):
        volume = disks[counter].mountpoint
        if disks[counter].opts != "cdrom":
            if osInfo == "Windows":
                volume = volume[:3].lower()
            diskInfo = psutil.disk_usage(volume)
            diskTotal = round((diskInfo.total/gB), 2)
            if diskTotal > 0:
                diskUsed = round((diskInfo.used / gB), 2)
                diskFree = round((diskTotal - diskUsed), 2)

                # Output Section
                diskIn = [
                    {'channel': 'Disk Total ' + volume + ':', 'value': diskTotal, 'float': '1', 'customunit': 'GB'},
                    {'channel': 'Disk Free ' + volume + ':', 'value': diskFree, 'float': '1', 'customunit': 'GB'},
                    {'channel': 'Disk Utilization ' + volume + ':', 'value': round(((diskUsed / diskTotal) * 100), 2),
                     'float': '1', 'customunit': '%', 'limitmaxwarning': '85', 'limitmaxerror': '95', 'limitmode': '1'}]
                diskOut = diskOut + diskIn
    #Disk IO
    diskIO = psutil.disk_io_counters(perdisk=True)
    disks=diskIO.keys()
    keys = []
    x = 0
    #Determine Disk List
    if osInfo == "Windows":
        for counter, value in enumerate(disks):
            if value[:13] == "PhysicalDrive":
                keys.append(value)
                x += 1
    elif osInfo == "Linux":
        for counter, value in enumerate(disks):
            if value[:2] == "sd" and len(value) == 3:
                keys.append(value)
                x += 1
    else:
        keys = disks
    #Get Disk IO for all disks.
    for counter, value in enumerate(keys):
        diskRead = round(((diskIO[value].read_bytes)/mB), 2)
        diskWrite = round(((diskIO[value].write_bytes)/mB), 2)
        #Output Section
        diskIn = [{'channel':'Disk Read ' + value + ':','value':diskRead,'float':'1','customunit':'MB'},
                  {'channel':'Disk Write ' + value + ':','value':diskWrite,'float':'1','customunit':'MB'}]
        diskOut = diskOut + diskIn
    return diskOut

#Generate The Combined JSON
def main():
    jsonIn=[]
    jsonIn = jsonIn + getCPU()
    jsonIn = jsonIn + getMEM()
    jsonIn = jsonIn + getNET()
    jsonIn = jsonIn + getDISK()
    #Output Section
    jsonOut=json.dumps(jsonIn)
    finalJSON = """{"prtg": {"result": """ + jsonOut + """}}"""
    return finalJSON
print main()
