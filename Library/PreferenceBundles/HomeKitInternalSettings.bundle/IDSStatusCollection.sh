#!/bin/bash

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Developer/usr/bin

idstool list | grep -A 6 willow && idstool devices -s com.apple.private.alloy.willow
