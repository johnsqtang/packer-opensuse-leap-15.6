#!/bin/bash

while [ ! -f /root/finished ]; do 
	echo 'Waiting for /root/finished ...'
	sleep 5
done

rm /root/finished

while [ ! -f /var/log/YaST2/y2log ] || ! (tail -n 20 /var/log/YaST2/y2log | grep -q installation_finish ); do
	echo 'Waiting for installation to finish ...'
	sleep 5
done

echo 'installation done.'

# a little more safe time to wait for.
sleep 25
