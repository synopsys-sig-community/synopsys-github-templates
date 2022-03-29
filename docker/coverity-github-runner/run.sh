#!/bin/bash

trap 'kill -INT $PID' TERM INT

if [ -f ".path" ]; then
    export PATH=`cat .path`
    echo ".path=${PATH}"
fi

# Insert Sunopsys PATH variables here
export PATH=~/cov-analysis-linux64/bin:$PATH

# run the host process which keep the listener alive
./externals/node12/bin/node ./bin/RunnerService.js &
PID=$!
wait $PID
trap - TERM INT
wait $PID
