#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Developer/usr/bin
source /AppleInternal/Library/PreferenceBundles/HomeKitInternalSettings.bundle/HomeKitLogCollectionScript.sh

hmLogs "$1" "$2"