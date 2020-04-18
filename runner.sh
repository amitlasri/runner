#!/bin/bash
# Configuring environment variable for convenient work during the script.
export COMMAND=$1

# Print help message
help(){
        cat <<EOF
  Usage: ${COMMAND} [-c COUNT] [--failed-count N] [--sys-trace] [--call-trace] [--log-trace] [--debug] [--help]
   -c COUNT             Number of times to run the given command"
   --failed-count N     Number of allowed failed command invocation attempts before giving up"
   --sys-trace          For each failed execution, create a log for each of the following values: Disk IO, Memory, Processes/threads and cpu usage of the command,                              Network card package counters"
   --call-trace         For each failed execution, add also a log with all the system calls ran by the command"
   --log-trace          For each failed execution, add also the command output logs (stdout,stderr)"
   --debug              Debug mode, show each instruction executed by the script"
   --help               Print a usage message to STDERR explaining how the script should be used"
EOF
exit
}

SHORT=c:
LONG=failed-count:,debug,sys-trace,net-trace,call-trace,log-trace

OPTS=$(getopt -o=${SHORT} --longoptions=${LONG} -n "$0" -- "$@")

# Checking that getopt ran properly- if one or more of the arguments are not vaild.
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

# If you want to use eval command to prevent quoting problems.
# after that, you should also change the export command in the loop:  export COUNT="$2" , export FAILED_COUNT="$2".
#eval set -- "${OPTS}"

# Set the values from ${OPTS} as arguments.
set -- ${OPTS}

# Define variables for the selected arguments
while (( "$#" )); do
        case $1 in
        -c)
            # Using 'tr' to remove the quotation marks from the argument value - to avoid using 'eval set -- "${OPTS}"' before the while loop.
            export COUNT=$(echo $2 | tr -d \' )
            shift 2 ;;
        --failed-count)
            # Using 'tr' to remove the quotation marks from the argument value - to avoid using 'eval set -- "${OPTS}"' before the while loop.
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

echo "count: ${COUNT}"
echo "failed-count: ${FAILED_COUNT}"
echo "sys-trace: ${SYS_TRACE}"
echo "net-trace: ${NET_TRACE}"
echo "call-trace: ${CALL_TRACE}"