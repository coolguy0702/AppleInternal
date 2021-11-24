#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Developer/usr/bin

log stream --style syslog --system --source --filter 'subsystem:"com.apple.HomeKit"'
