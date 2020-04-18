#!/bin/bash

## Here i tried to figure out how to write the summary function and how to count the occurrences of each return code.

#sed -i '/^$/d' return_codes.txt
#awk '{for (i=1;i<=NF;i++) a[$i]++} END{for (c in a) print c,a[c]}' FS="" return_codes.txt > tmp && mv tmp return_codes.txt
#sort return_codes.txt | uniq -c | sort -r | awk '{print $2,$1}' OFS='\t' > tmp && mv tmp return_codes.txt
#sed -i '1i Exit-Code Count' return_codes.txt
#printf "_____Summary_____\n"
#cat return_codes.txt | column -t -o" | "

## here i tried to figure out how to run the sys_trace function.

export SCRIPT_START_TIME=$(date + '%Y%m%d_%H:%M:%D')
sys_trace
sys_trace() {
export SYS_TRACE_FILE=./sys_trace_${SCRIPT_START_TIME}.log
export SYS_TRACE_START=${START_TIME##*_}
#sar -n ALL -P ALL -r -u ALL >> ${SYS_TRACE_FILE} >/dev/null 2>&1
#sar -n ALL -P ALL -r -u ALL  >> ${SYS_TRACE_FILE} >/dev/null 2>&1
#sar -n ALL -P ALL -r -u ALL -s ${SYS_TRACE_START} -e ${SYS_TRACE_END} -o ${SYS_TRACE_FILE} >/dev/null 2>&1
sar -n ALL -P ALL -r -u ALL > ${SYS_TRACE_FILE} >/dev/null 2>&1 &
#${COMMAND} & >/dev/null 2>&1
#wait
}