#!/bin/bash
TMPROOT=/private/var/tmp/libmicro
rm -rf $TMPROOT 2>/dev/null
mkdir -p $TMPROOT

TFILE=$TMPROOT/data
IFILE=$TMPROOT/ifile
TDIR1=$TMPROOT/0/1/2/3/4/5/6/7/8/9
TDIR2=$TMPROOT/1/2/3/4/5/6/7/8/9/0

dd if=/dev/zero of=$TFILE bs=1024k count=10 2>/dev/null
mkdir -p $TDIR1 $TDIR2

touch $IFILE
/usr/bin/touch /private/var/tmp/lmbench

