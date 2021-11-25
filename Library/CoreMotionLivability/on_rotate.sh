#!/bin/bash
#
#  on_rotate.sh
#  Core Motion Livability
#
#  Created by Paul Thompson on 9/24/16.
#  Copyright © 2016-2018 Apple. All rights reserved.
#

staging="$1"

## Grabbing Locationd Defaults
loctool serialize_settings "$staging/locationd_defaults.plist"


## Collecting device info
gestalt_query HWModelStr ProductType BuildVersion SerialNumber UniqueDeviceID UniqueChipID > "$staging"/device_info.txt
paired_to=( $(pairtool report serialNumber) )
for i in "${paired_to[@]}"; do echo "PairedTo: \"${i}\"" >> "$staging"/device_info.txt; done

# Screen orientation
login -fq mobile defaults read com.apple.nano >> "$staging"/device_info.txt

sensors=('accel' 'gyro' 'compass' 'pressure')
for sensor in "${sensors[@]}";
do
    spuctl --sensorinfo "$sensor" | grep Device | awk -v sensor="$sensor" '{ print sensor " : " $NF }' >> "$staging"/device_info.txt
done

darwinup list >> "$staging"/device_info.txt


## Grabbing partition info
du -k /var/mobile/Documents/com.apple.CoreMotionLivability /var/root/Library/Caches/locationd > "$staging"/partition_health.txt
echo ----------------------------------------------------------- >> "$staging"/partition_health.txt
df -k "$staging" >> "$staging"/partition_health.txt

delete_option="-mindepth 1 -maxdepth 1 -delete"


## Grab HeartRateSensor Files
if [[ -d /var/mobile/Library/Logs/CrashReporter/HeartRateSensor ]]; then
    tar -cvf "${staging}/HeartRateSensor.tar.gz" -C /var/mobile/Library/Logs/CrashReporter/HeartRateSensor ./
    find /var/mobile/Library/Logs/CrashReporter/HeartRateSensor $delete_option
fi


## Grabbing HR App files
hr_dir="$(mobile_install lookup com.apple.HeartRate | grep dataContainerURL | sed 's%dataContainerURL = file://%%')"
if [[ -d "${hr_dir}" ]]; then
    killall HeartRate
    tar -czvf "${staging}/HeartRateApp.tar.gz" -C "${hr_dir}/Documents" ./
    find "${hr_dir}/Documents" $delete_option
fi


## Grabbing Solar Compass Files
solar_dir="$(mobile_install lookup com.apple.cmqa.solarcompass | grep dataContainerURL | sed 's%dataContainerURL = file://%%')"
if [[ -d "${solar_dir}" ]]; then
    tar -czvf "${staging}/SolarCompass.tar.gz" -C "${solar_dir}/Documents/com.apple.cmqa.solarcompass" ./
    find "${solar_dir}/Documents/com.apple.cmqa.solarcompass" $delete_option
fi
