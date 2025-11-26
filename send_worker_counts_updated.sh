#!/bin/ksh

# Get the PID of the mcman parent process
mcman_pid=$(ps -ef | grep mcman | grep -v grep | awk '{print $2}')
if [ -z "${mcman_pid}" ]; then
  echo "mcman process not found."
  mcman_count=0
else
  mcman_count=$(ps -eo ppid | grep "^ *${mcman_pid}" | wc -l)
fi

# Send the count to Datadog via DogStatsD
echo "mcman.worker_processes:${mcman_count}|g" | nc -u -w0 127.0.0.1 8125
echo "Sent mcman.worker_processes:${mcman_count} to Datadog via DogStatsD"

# Get the PID of the mworkermonitor parent process
mworkermonitor_pid=$(ps -ef | grep mworkermonitor | grep -v grep | awk '{print $2}')
if [ -z "${mworkermonitor_pid}" ]; then
  echo "mworkermonitor process not found."
  mworkermonitor_count=0
else
  mworkermonitor_count=$(ps -eo ppid | grep "^ *${mworkermonitor_pid}" | wc -l)
fi

# Send the count to Datadog via DogStatsD
echo "mworkermonitor.worker_processes:${mworkermonitor_count}|g" | nc -u -w0 127.0.0.1 8125
echo "Sent mworkermonitor.worker_processes:${mworkermonitor_count} to Datadog via DogStatsD"

# Get the PID of the mlockmand parent process
mlockmand_pid=$(ps -ef | grep mlockmand | grep -v grep | awk '{print $2}')
if [ -z "${mlockmand_pid}" ]; then
  echo "mlockmand process not found."
  mlockmand_count=0
else
  mlockmand_count=$(ps -eo ppid | grep "^ *${mlockmand_pid}" | wc -l)
fi

# Send the count to Datadog via DogStatsD
echo "mlockmand.worker_processes:${mlockmand_count}|g" | nc -u -w0 127.0.0.1 8125
echo "Sent mlockmand.worker_processes:${mlockmand_count} to Datadog via DogStatsD"

# Get the PID of the mdebugsvrd parent process
mdebugsvrd_pid=$(ps -ef | grep mdebugsvrd | grep -v grep | awk '{print $2}')
if [ -z "${mdebugsvrd_pid}" ]; then
  echo "mdebugsvrd process not found."
  mdebugsvrd_count=0
else
  mdebugsvrd_count=$(ps -eo ppid | grep "^ *${mdebugsvrd_pid}" | wc -l)
fi

# Send the count to Datadog via DogStatsD
echo "mdebugsvrd.worker_processes:${mdebugsvrd_count}|g" | nc -u -w0 127.0.0.1 8125
echo "Sent mdebugsvrd.worker_processes:${mdebugsvrd_count} to Datadog via DogStatsD"

# Get the PID of the maccept_handler parent process
maccept_handler_pid=$(ps -ef | grep maccept_handler | grep -v grep | awk '{print $2}')
if [ -z "${maccept_handler_pid}" ]; then
  echo "maccept_handler process not found."
  maccept_handler_count=0
else
  maccept_handler_count=$(ps -eo ppid | grep "^ *${maccept_handler_pid}" | wc -l)
fi

# Send the count to Datadog via DogStatsD
echo "maccept_handler.worker_processes:${maccept_handler_count}|g" | nc -u -w0 127.0.0.1 8125
echo "Sent maccept_handler.worker_processes:${maccept_handler_count} to Datadog via DogStatsD"
