#!/bin/sh
#
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms
# of the Common Development and Distribution License
# (the "License").  You may not use this file except
# in compliance with the License.
#
# You can obtain a copy of the license at
# src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing
# permissions and limitations under the License.
#
# When distributing Covered Code, include this CDDL
# HEADER in each file and include the License file at
# usr/src/OPENSOLARIS.LICENSE.  If applicable,
# add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your
# own identifying information: Portions Copyright [yyyy]
# [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#


# usage function - defines all the options that can be given to this script.
function usage {
	echo "Usage"
	echo "$0 [-l] [-h] [name of test]"
	echo "-l               : This option runs the lmbench tests along with the default libmicro tests."
	echo "-h               : Help. This option displays information on how to run the script. "
	echo "[name of test]   : This option runs only the test that is specified"
	echo ""
	echo "Examples"
	echo "$0               : This is the default execution. This will run only the default libmicro tests."
	echo "$0 -l            : This will run the lmbench tests too "
	echo "$0 getppid       : This will run only the getppid tests"
	exit
}

opt_perfdata=0
opt_small_output=0

function main {
	TMPROOT=/private/var/tmp/libmicro.$$
	VARROOT=/private/var/root/libmicro.$$
	mkdir -p $TMPROOT
	mkdir -p $VARROOT
	trap "rm -rf $TMPROOT $VARROOT && exit" 0 2

	TFILE=$TMPROOT/data
	IFILE=$TMPROOT/ifile
	TDIR1=$TMPROOT/0/1/2/3/4/5/6/7/8/9
	TDIR2=$TMPROOT/1/2/3/4/5/6/7/8/9/0
	VFILE=$VARROOT/data
	VDIR1=$VARROOT/0/1/2/3/4/5/6/7/8/9
	VDIR2=$VARROOT/1/2/3/4/5/6/7/8/9/0


	OPTS="-C 200"
	if [ $opt_perfdata -eq 0 ]; then
		OPTS="$OPTS -p"
	fi
	if [ $opt_small_output -eq 0 ]; then
		OPTS="$OPTS -S"
	fi

	dd if=/dev/zero of=$TFILE bs=1024k count=10 2>/dev/null
	dd if=/dev/zero of=$VFILE bs=1024k count=10 2>/dev/null
	mkdir -p $TDIR1 $TDIR2
	mkdir -p $VDIR1 $VDIR2

	touch $IFILE
	/usr/bin/touch /private/var/tmp/lmbench

	# produce benchmark header for easier comparisons

	hostname=`uname -n`

	if [ -f /usr/sbin/psrinfo ]; then
		p_count=`psrinfo|wc -l`
		p_mhz=`psrinfo -v | awk '/operates/{print $6 "MHz"; exit }'`
		p_type=`psrinfo -vp 2>/dev/null | awk '{if (NR == 3) {print $0; exit}}'` 
		p_ipaddr=`getent hosts $hostname | awk '{print $1}'`
	fi

	if [ -f /proc/cpuinfo ]; then
		p_count=`egrep processor /proc/cpuinfo | wc -l`
		p_mhz=`awk -F: '/cpu MHz/{printf("%5.0f00Mhz\n",$2/100); exit}' /proc/cpuinfo`
		p_type=`awk -F: '/model name/{print $2; exit}' /proc/cpuinfo`
		p_ipaddr=`getent hosts $hostname | awk '{print $1}'`
	else
	## Darwin-specific stuff
	# first, get ugly output, in case pretty output isn't available
	#
		p_count=`sysctl -n hw.physicalcpu`
		p_mhz=`sysctl -n hw.cpufrequency`
		p_type=`sysctl -n hw.model`

	if [ -x /usr/sbin/system_profiler ]; then
		# <rdar://4655981> requires this hunk of work-around
		# grep the XML for the characteristic we need. The key appears twice, so grep for the useful key (with 'string')
		# use sed to strip off the <string></string> and the tabs in front of the string.  So much work for so little result.
		#
			p_mhz=`system_profiler -xml -detailLevel mini SPHardwareDataType | \
				grep -A1 current_processor_speed | grep string | \
				sed -E 's/<string>(.+)<\/string>/\1/' | sed 's-	--g'`
			p_type=`system_profiler -xml -detailLevel mini SPHardwareDataType | \
				grep -A1 cpu_type | grep string | \
				sed -E 's/<string>(.+)<\/string>/\1/' | sed 's-	--g'`
	fi

	# look for en0 (usually ethernet) if that isn't there try en1 (usually wireless) else give up
		p_ipaddr=`ipconfig getpacket en0 | grep yiaddr | tr "= " "\n" | grep [0-9]`
		if [ ! $p_ipaddr  ]; then
			p_ipaddr=`ipconfig getpacket en1 | grep yiaddr | tr "= " "\n" | grep [0-9]`
		elif [ ! $p_ipaddr ]; then
			p_ipaddr="unknown"
		fi
	fi

	printf "\n\n!Libmicro_#:   %30s\n" $libmicro_version
	printf "!Options:      %30s\n" "$OPTS"
	printf "!Machine_name: %30s\n" "$hostname"
	printf "!OS_name:      %30s\n" `uname -s`
	printf "!OS_release:   %30s\n" `sw_vers -productVersion`
	printf "!OS_build:     %30.18s\n" "`sw_vers -buildVersion`"
	printf "!Kernel:       %30.50s\n" "`uname -v|cut -d ' ' -f 11`"
	printf "!Processor:    %30s\n" `arch`
	printf "!#CPUs:        %30s\n" $p_count
	printf "!CPU_MHz:      %30s\n" "$p_mhz"
	printf "!CPU_NAME:     %30s\n" "$p_type"
	printf "!IP_address:   %30s\n" "$p_ipaddr"
	printf "!Run_by:       %30s\n" $LOGNAME
	printf "!Date:	       %30s\n" "`date '+%D %R'`"

	bin_dir="$TMPROOT/bin"

	mkdir -p $bin_dir
	cp exec_bin $bin_dir/$A
	cp /AppleInternal/Tests/libMicro/assets/HASH_INPUT.txt $bin_dir/$A

	newline=0

	#
	# Everything below the while loop is input for the while loop
	# if you have any tests which can't run in the while loop, put
	# them above this comment
	while read A B
	do
		# $A contains the command, $B contains the arguments
		# we echo blank lines and comments
		# we skip anything which fails to match *$1* (useful if
		# we only want to test one case, but a nasty hack)

		case $A in
		\#*)
			echo "$A $B"
			newline=1
			continue
			;;

		"")
			if [ $newline -eq 1 ]
			then
				newline=0
				echo
				echo
			fi

			continue
			;;

		*$1*)
			# Default execution without the lmbench tests. 
			# checks if there is no argument passed by the user.
			if [  $lmbench -eq 0 ]
			then
				string=lmbench
				if [ "${A:0:7}" == "$string" ]
				then
					continue
				fi
			fi

			;;

		*)		
			if [ $lmbench -ne 1 ]
			then
				continue
			fi
			;;
		esac

		if [ ! -f $bin_dir/$A ]
		then
			cp $A $bin_dir/$A
		fi

		echo

		(cd $TMPROOT && eval "bin/$A $OPTS $B")

		echo
	done < ./tests
}

if [ $# -eq 1 ]
then
	lmbench=2    # to check if only a single test is to be run. e.g, ./bench.sh getppid
else
	lmbench=0    # to run the default libMicro tests, without the lmbench tests.
fi

while getopts "hlps" OPT_LIST
do
	case $OPT_LIST in
		h) usage;;
		p) opt_perfdata=1; opt_small_output=1;;
		s) opt_small_output=1;;
		*) usage;;
	esac
done

lmbench=1


launchctl load com.apple.*
main | tee $HOME/bench.log-`date "+%H-%M-%S-%m-%d-%Y"`
launchctl unload com.apple.*
