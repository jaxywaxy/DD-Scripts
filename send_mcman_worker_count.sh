#!/bin/ksh

# Get the PID of the mcman parent process
mcman_pid=$(ps -ef | grep mcman | grep -v grep | awk '{print $2}')

# Check if mcman is running
if [ -z "$mcman_pid" ]; then
  echo "mcman process not found."
  exit 1
fi

# Count the number of child processes spawned by mcman
worker_count=$(ps -eo ppid | grep "^ *$mcman_pid" | wc -l)

# Send the count to Datadog via DogStatsD
# Replace 127.0.0.1 with your DogStatsD host if different
# Replace 8125 with your DogStatsD port if different
echo "mcman.worker_processes:$worker_count|g" | nc -u -w0 127.0.0.1 8125

# Print confirmation
echo "Sent mcman.worker_processes:$worker_count to Datadog via DogStatsD"
