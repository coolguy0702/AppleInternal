#!/bin/sh

while getopts 'h' OPTION;
do
        case "$OPTION" in
                h ) echo "Usage: ./nvread.sh"; exit 1;;
                /?)     echo "INVALID OPTIONS.\n"; exit 1;;
        esac
done
shift $(($OPTIND - 1))

echo "============= NV Read =============="
ETLTool ping > nvreadlog.txt
ETLTool ping
ETLTool ping
echo "============= NV Read ==============" >> nvreadlog.txt
date >> nvreadlog.txt
ETLTool nvread 465 >> nvreadlog.txt
ETLTool nvread 466 >> nvreadlog.txt
ETLTool nvread 1192 >> nvreadlog.txt
ETLTool nvread 62004 >> nvreadlog.txt
ETLTool nvread 62005 >> nvreadlog.txt
ETLTool nvread 62006 >> nvreadlog.txt
ETLTool nvread 62019 >> nvreadlog.txt
echo "============= NV Read Done ==============" >> nvreadlog.txt
cat nvreadlog.txt >> nvreadlogAll.txt
cat nvreadlog.txt
