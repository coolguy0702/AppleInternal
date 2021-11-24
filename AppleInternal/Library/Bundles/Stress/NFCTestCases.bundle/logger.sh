#!/bin/bash

log stream --system --filter 'subsystem:"com.apple.nfc"' --style syslog &> ~/Library/Logs/WirelessStress/nftool.log
