
Esy Sunhome RS485 RJ45 connector:
Pin 4: -/B
Pin 5: +/A


For a USB RS485 converter try:
mbpoll -1 -m rtu -b 9600 -P none -a 1 -r 1 -c 100 /dev/ttyUSB0 -t 3

For a TCP modbus bridge try:
mbpoll -m tcp -a 1 -r 1 -c 100 -t 3 <ip_addr>:4196



Added a simple HTML file that can be run locally to get the inverter ID: esy_sunhome_id.html
