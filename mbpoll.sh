#!/bin/bash
# -t=3 read modbus input registers
mbpoll -m rtu -b 9600 -P none -a 1 -r 1 -c 100 /dev/ttyUSB0 -t 3 -l 1000
