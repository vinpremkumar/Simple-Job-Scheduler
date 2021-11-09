#!/bin/bash

#echo "Application prefix: <app name>"

########
## GLOBAL SETTINGS
## INPUT
## Make this as input from APP GUI later
########
MAX_ACTIVE_PROCESS_COUNT=2 	# Number of processes that run at the same time; Other processes gets queued
MAX_CPU_USAGE=200		# Max CPU percentage that can be utilized by the app
				# If Hyper-threading is enabled, then each thread is considered a CPU
				# A MAX_CPU_USAGE=200 corresponds to 2 threads being utilized at 100% 

######################################################################################################

########
## Variable Declaration
########
declare -i LEN_VAR 		# Declare it as an integer for performing math on it
#declare -i CPU_PERCENT 	# Total CPU % used by all processes
declare -i QUEUE_FLAG 		# Queue Flag
declare -i PROCESS_COUNT 	# Number of active running processes
#########
## Get ps output into individual arrays]
########
APP="python"   ## CHANGE THIS TO YOUR APP NAME

while true; do

IFS=$'\n' read -r -d '' -a USR_ARR < <( ps --sort=lstart -e -o user -o %c | grep $APP && printf '\0' )
IFS=$'\n' read -r -d '' -a PID_ARR < <( ps --sort=lstart -e -o %p -o %c | grep $APP && printf '\0' )
IFS=$'\n' read -r -d '' -a PPID_ARR < <( ps --sort=lstart -e -o ppid -o %c | grep $APP && printf '\0' )
IFS=$'\n' read -r -d '' -a START_ARR < <( ps --sort=lstart -e -o start -o %c | grep $APP && printf '\0' )
IFS=$'\n' read -r -d '' -a MEM_ARR < <( ps --sort=lstart -e -o pmem -o %c | grep $APP && printf '\0' )

########
## Variable Initilization
########
LEN_VAR=0
tmp_CPU_PERCENT=0
CPU_PERCENT=0
QUEUE_FLAG=0
PROCESS_COUNT=0

NUM_OF_THREADS=$(echo $(nproc))	# Total number of CPU(s) seen by the program

## Find the length (total number of processes)
LEN_VAR="${#PID_ARR[@]}"-1 	# '-1' is because the array index starts from 0
#echo $LEN_VAR

########
## Parsing so that only the required data is left in the array
## If not, ",<app name>" is combined in the array values
########
for i in $(seq 0 1 $LEN_VAR)
do
#    echo $i

## USER-ID
    read -ra tmp <<< "${USR_ARR[i]}"
    USR_LIST[i]=${tmp[0]}
#    echo ${USR_LIST[i]}

## PID
    read -ra tmp <<< "${PID_ARR[i]}"
    PID_LIST[i]=${tmp[0]}
#    echo ${PID_LIST[i]}

## PPID
    read -ra tmp <<< "${PPID_ARR[i]}"
    PPID_LIST[i]=${tmp[0]}
#    echo ${PPID_LIST[i]}

# START
   read -ra tmp <<< "${START_ARR[i]}"
   START_LIST[i]=${tmp[0]}
#   echo ${START_LIST[i]}

## CPU
    tmp_CPU_LIST=$(top -b -n 2 -d 0.2 -p ${PID_LIST[i]} | tail -1 | awk '{print $9}' )
    CPU_PERCENT=$(echo "($tmp_CPU_LIST + $CPU_PERCENT) / $NUM_OF_THREADS" | bc ) # Total CPU % used by all processes
    CPU_LIST[i]=$(echo "$tmp_CPU_LIST" | bc)
#    echo ${CPU_LIST[i]}
#    echo ${PID_LIST[i]}

## PMEM
    read -ra tmp <<< "${MEM_ARR[i]}"
    MEM_LIST[i]=${tmp[0]}
#    echo ${MEM_LIST[i]}


########
## Find parent and child processes
########
## Initialize parent_FLAG to denote its a parent process
## Parent process should not be killed
## So find the parent and ignore it from queueing
    PARENT_FLAG[i]=0

## Set parent_FLAG=1 if parent process
    for j in $(seq 0 1 $LEN_VAR)    
    do
        if [ "${PPID_LIST[i]}" == "${PID_LIST[j]}" ]
        then
            PARENT_FLAG[j]=1
#            echo ${PARENT_FLAG[@]}
        fi    
    done

done

########
## Sorting for providing priority parameter
########
# Since we used --sort=lstart in ps command, the list is already sorted
# So higher priority = lower index value

########
## Output
########
clear # Clear the screen
echo " "
echo " "
printf "%-15s | %-15s | %-10s | %-10s | %-10s | %-10s |\n" "USER-ID" " START TIME" "PID" "CPU %" "MEM %"  "STATUS"

########
## Queue processor clones
########
for i in $(seq 0 1 $LEN_VAR)
do
    if [ ${PARENT_FLAG[i]} != 1 ]
    then    
        if [ $QUEUE_FLAG != 1 ]
        then
#            echo ${PARENT_FLAG[@]} 
#            echo $i
            kill -CONT ${PID_LIST[i]}
	    STATUS_FLAG[i]="Running"        

            PROCESS_COUNT+=1
            
            if [ $PROCESS_COUNT -ge $MAX_ACTIVE_PROCESS_COUNT ]
            then
                QUEUE_FLAG=1
                # QUEUE_FLAG variable is not necessary but has been used for eligiblility of the code
             else 
                if (( $(echo "$CPU_PERCENT >= $MAX_CPU_USAGE" | bc -l) ))  
                then
                    QUEUE_FLAG=1 
#                    echo "QUEUE=$QUEUE_FLAG"
	  	fi
             fi
        else
            kill -STOP ${PID_LIST[i]}
	    STATUS_FLAG[i]="Queued"
        fi  

printf "%-15s | %-15s | %-10s | %-10s | %-10s | %-10s |\n" "${USR_LIST[i]}" "${START_LIST[i]}" "${PID_LIST[i]}" "${CPU_LIST[i]}" "${MEM_LIST[i]}" "${STATUS_FLAG[i]}"

    fi
done

echo " "
echo " "
echo "Total CPU % used by App   : $CPU_PERCENT"
echo "No. of active jobs        : $PROCESS_COUNT"
echo " "
echo " "

## Wait time before refreshing values
sleep 1

done
