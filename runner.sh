#!/bin/bash

# Configuring environment variables
export COMMAND=$1
export SCRIPT_START_TIME=$(date +"%Y-%m-%d_%H:%M:%S")
export EXEC_COUNT=0
export EXEC_FAILED=0

# Print help message
help(){
        cat <<EOF
  Usage: ${COMMAND} [-c COUNT] [--failed-count N] [--sys-trace] [--call-trace] [--log-trace] [--debug] [--help]
   -c COUNT             Number of times to run the given command
   --failed-count N     Number of allowed failed command invocation attempts before giving up
   --sys-trace          For each failed execution, create a log for each of the following values: Disk IO, Memory, Processes/threads and cpu usage of the command, Network card package counters
   --call-trace         For each failed execution, also add a log with all the system calls ran by the command
   --log-trace          For each failed execution, add also the command output logs (stdout,stderr)
   --debug              Debug mode, show each instruction executed by the script
   --help               Print a usage message to STDERR explaining how the script should be used
EOF
exit
}

SHORT=c:
LONG=failed-count:,debug,sys-trace,net-trace,call-trace,log-trace

OPTS=$(getopt -o=${SHORT} --longoptions=${LONG} -n "$0" -- "$@")

# Checking that getopt ran properly- if one or more of the arguments are not valid.
if [[ $? != 0 ]]; then
        help
fi

# Check if no option sent to the script
if [[ $# == 1 ]] ;then
        echo "No special options, running the command only"
        ${COMMAND}
        exit
elif [[ $# == 0 ]] ;then
        echo "No argument has been sent to the script."
        help
fi

# If you want you could use the eval command to prevent quoting problems. -
# after that, you should also change the export command in the loop:  export COUNT="$2" , export FAILED_COUNT="$2".
#eval set -- "${OPTS}"

# Set the values from ${OPTS} as arguments.
set -- ${OPTS}

# Define variables for the selected arguments
while (( "$#" )); do
        case $1 in
        -c)
            # Using 'tr' to remove the quotation marks from the argument value thus avoiding using 'eval set -- "${OPTS}"' before the while loop.
            export COUNT=$(echo $2 | tr -d \' )
            shift 2 ;;
        --failed-count)
            # Using 'tr' to remove the quotation marks from the argument value thus avoiding using 'eval set -- "${OPTS}"' before the while loop.
            export FAILED_COUNT=$(echo $2 | tr -d \' )
            shift 2 ;;
        --sys-trace)
            export SYS_TRACE="YES"
            shift  ;;
        --debug)
            # Start the debug mode
            set -xv
            shift ;;
        --call-trace)
            export CALL_TRACE="YES"
            shift ;;
        --net-trace)
            export NET_TRACE="YES"
            shift ;;
        --log-trace)
            export LOG_TRACE="YES"
            shift ;;
        --)
            # End of arguments
            shift
            break ;;
         *)
            # The input didn't match none of the above options.
            help
            ;;
    esac
done

# For each failed execution, create a log for each of the following values, measured during command execution: Disk IO, Memory, Processes/threads and cpu usage of the command, Network card package counters.
# Using sar command requires start and end time in format of %H:%M[:%S]. in this case i used %H:%M to generate a more detailed output.
sys_trace() {
export SYS_TRACE_FILE=./sys_trace_${START_TIME}.log
#export SYS_TRACE_START=${START_TIME##*_}
export SYS_TRACE_START=$(echo ${START_TIME##*_} | cut -c-5)
sar 1 3 -n ALL -P ALL -r -u ALL >> ${SYS_TRACE_FILE} & >/dev/null 2>&1
${COMMAND} >/dev/null 2>&1 &
cat ${SYS_TRACE_FILE} | grep ${SYS_TRACE_START} > tmp && mv tmp ${SYS_TRACE_FILE}
wait
}

# For each failed execution create a ‘pcap’ file with the network traffic during the execution.
net_trace(){
export NET_TRACE_PCAP=./net_trace_${START_TIME}.pcap
tcpdump -U -i any -nnN -t -s 0 -c 20 -w ${NET_TRACE_PCAP} >/dev/null 2>&1 &
${COMMAND} >/dev/null 2>&1 &
wait
}

# For each failed execution create log with all of the system calls ran by the command.
call_trace(){
export CALL_TRACE_FILE=./call_trace-${SCRIPT_START_TIME}.log
strace -ttT -o ${CALL_TRACE_FILE} ${COMMAND} >/dev/null 2>&1
}

# For each failed execution create stdout and stderr log files with the output of the command.
log_trace(){
export STDOUT_FILE=./log_trace-${SCRIPT_START_TIME}.out
export STDERR_FILE=./log_trace-${SCRIPT_START_TIME}.err
${COMMAND} 2>>${STDERR_FILE} 1>>${STDOUT_FILE}
}

# Print a summary of the command return codes.
summary(){
# Check if return_codes file is not exists- (probably in case that only '--failed-count' option exists without '-c').
if [[ ! -f ./return_codes.txt ]] ; then
    touch "./return_codes.txt"
    echo "No command has been running. please check again your argument options"
    help
else
    # Remove empty lines
    sed -i '/^$/d' return_codes.txt
    # Counts occurrences of each line and prints the return code and the count.
    sort return_codes.txt | uniq -c | sort -r | awk '{print $2,$1}' OFS='\t' > tmp && mv tmp return_codes.txt
    # Insert to the first line in file the titles.
    sed -i '1i Exit-Code Count' return_codes.txt
    printf "_____Summary_____\n"
    cat return_codes.txt | column -t -o" | "
    rm -f ./return_codes.txt
fi
}

# Make sure that summary will be printed at any case of exit signals.
trap summary SIGINT SIGQUIT SIGTSTP

# Check if --failed-count is not sent as argument to the script. in case that only -c exists.
if [[ -z ${FAILED_COUNT} ]] ;then
        echo "no failed count option configured"
        while [[ ${EXEC_COUNT} -lt ${COUNT} ]] ;do
                ${COMMAND} < /dev/null 2>&1
                export RESULT=$(echo "$?")
                echo "${RESULT}" >> ./return_codes.txt
                ((EXEC_COUNT++))
        done
else

# Running until getting to the limit of 'count' or 'failed-count' parameters.
while [[ ${EXEC_COUNT} -lt ${COUNT} ]] && [[ ${EXEC_FAILED} -lt ${FAILED_COUNT} ]] ; do
    export START_TIME=$(date +"%Y-%m-%d_%H:%M:%S")
    ${COMMAND} > /dev/null 2>&1
    export RESULT=$(echo "$?")
    echo "${RESULT}" >> ./return_codes.txt

    # If the command failed:
    if [[ ${RESULT} != 0 ]] ; then
            if [[ ${NET_TRACE} == "YES" ]]; then
                    net_trace
            fi
            if [[ ${SYS_TRACE} == "YES" ]]; then
                    sys_trace
            fi
            if [[ ${CALL_TRACE} == "YES" ]]; then
                    call_trace &
                    wait
            fi
            if [[ ${LOG_TRACE} == "YES" ]]; then
                    log_trace &
                    wait
            fi

            ((EXEC_FAILED++))
    fi

    ((EXEC_COUNT++))

done

fi

## End of the script - calling to the summary function
summary
