#!/usr/bin/env bash

# Solution to Task 14 (Day 9: Requests) in bash instead of suggested python
# note requires that 'jq' is installed, a command-line json parser

path=""
flag=""
stop=0
while [ $stop -eq 0 ]
do
    json=`curl -s 10.10.169.100:3000/$path`
    value=`echo $json | jq -r .value`
    next=`echo $json | jq -r .next`

    if [ $value = "end" ]
    then
        stop=1
    else
        flag="$flag$value"
        echo $flag
        path=$next
    fi
done