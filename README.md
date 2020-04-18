**runner.sh**

**This is a bash script called **runner.sh** that wraps any other command and outputs a summary of execution, similar to the ping command, with the following options:**

    ● -c COUNT - Number of times to run the given command

    ● --failed-count N - Number of allowed failed command invocation attempts before giving up

    ● --sys-trace - For each failed execution, create a log for each of the following values,measured during command execution:
      ○ Disk IO
      ○ Memory
      ○ Processes/threads and cpu usage of the command
      ○ Network card package counters

    ● --call-trace - For each failed execution, add also a log with all the system calls ran by the command

    ● --log-trace - For each failed execution, add also the command output logs (stdout, stderr)

    ● --debug - Debug mode, show each instruction executed by the script.

    ● --help - Print a usage message to STDERR explaining how the script should be used.

    ● --net-trace - For each failed execution, create a ‘pcap’ file with the network traffic during the execution.


**Once completed, the script will:**

    ● Print a summary of the command return codes (how many times each return code happened), even if/when the script was interrupted (via ctrl+c or ‘kill’)

    ● Return the most frequent return code when exiting

**Requirements:**

    ● 'tcpdump' command

**Resources:**

    ● https://stackoverflow.com/
    ● Other sites from google searches.

**Challenges:**

    ● sar command to print all the relevant information during the execution of the command. parameter -s and -e didn't catch anything in the current millisecond.
    ● 'tcpdump' without Ctrl C that terminate all the script.
    ● working with 'getopts'
    ● avoid using eval command.





