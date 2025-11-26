#!/bin/ksh

# Define DogStatsD target
DOGSTATSD_HOST=127.0.0.1
DOGSTATSD_PORT=8125

# Loop through each process name
for PROC in mcman mworkermonitor mlockmand mdebugsvrd maccept_handler
do
  # Get the PID of the parent process
  PID=$(ps -ef | grep $PROC | grep -v grep | awk '{print $2}')
  if [ -z "$PID" ]; then
    echo "$PROC process not found."
    COUNT=0
  else
    COUNT=$(ps -eo ppid | grep "^ *$PID" | wc -l)
  fi

  # Send the count to Datadog via DogStatsD
  echo "$PROC.worker_processes:$COUNT|g" | nc -u -w0 $DOGSTATSD_HOST $DOGSTATSD_PORT
  echo "Sent $PROC.worker_processes:$COUNT to Datadog via DogStatsD"
done