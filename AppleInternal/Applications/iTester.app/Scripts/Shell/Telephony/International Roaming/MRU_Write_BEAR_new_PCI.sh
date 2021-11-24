#!/bin/sh

while getopts 'h' OPTION;
do
        case "$OPTION" in
                h ) echo "Usage: ./MRU_Write_BEAR.sh"; exit 1;;
                /?)     echo "INVALID OPTIONS.\n"; exit 1;;
        esac
done
shift $(($OPTIND - 1))



echo "============= MRU_Write_BEAR =============="
ETLTool ping > nvwritelog.txt
ETLTool ping
ETLTool ping
echo "============= MRU_Write_BEAR Begin ==============" >> nvwritelog.txt
date >> nvwritelog.txt
echo "[ Before Write ] " >> nvwritelog.txt



ETLTool ping
ETLTool efs-get prim /sd/mru001 264 >> nvwritelog.txt
ETLTool ping
ETLTool efs-put prim /sd/mru001 777 02 00 28 00 28 00 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 F2 00 40 00 fa 00 00 00 ff 00 1f 00 ff 3f 01 09 01 09 00 00 02 00 C9 00 28 00 fa 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 02 00 1B 01 28 00 06 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 0a 13 01 84 ff ff ff ff ff ff ff 00 1f 00 ff 3f 01 09 01 09 00 00 0a 13 01 84 ff ff ff ff ff ff ff 00 1f 00 ff 3f 01 09 01 09 00 00 02 00 83 01 28 00 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 >> nvwritelog.txt

ETLTool nvread 722 >> nvwritelog.txt
ETLTool nvwrite 722 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
ETLTool nvread 723 >> nvwritelog.txt
ETLTool nvwrite 723 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool nvread 737 >> nvwritelog.txt
ETLTool nvwrite 737 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool nvread 738 >> nvwritelog.txt
ETLTool nvwrite 738 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool nvread 739 >> nvwritelog.txt
ETLTool nvwrite 739 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool nvread 5080 >> nvwritelog.txt
ETLTool nvwrite 5080 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5081 >> nvwritelog.txt
ETLTool nvwrite 5081 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5082 >> nvwritelog.txt
ETLTool nvwrite 5082 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5083 >> nvwritelog.txt
ETLTool nvwrite 5083 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5084 >> nvwritelog.txt
ETLTool nvwrite 5084 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5085 >> nvwritelog.txt
ETLTool nvwrite 5085 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5086 >> nvwritelog.txt
ETLTool nvwrite 5086 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 5087 >> nvwritelog.txt
ETLTool nvwrite 5087 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool nvread 1190 >> nvwritelog.txt
ETLTool nvwrite 1190 0x00 0x00
ETLTool nvread 1894 >> nvwritelog.txt
ETLTool nvwrite 1894 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
echo "[ After Write ] " >> nvwritelog.txt

ETLTool nvread 722 >> nvwritelog.txt
ETLTool nvread 723 >> nvwritelog.txt
ETLTool nvread 737 >> nvwritelog.txt
ETLTool nvread 738 >> nvwritelog.txt
ETLTool nvread 739 >> nvwritelog.txt
ETLTool nvread 5080 >> nvwritelog.txt
ETLTool nvread 5081 >> nvwritelog.txt
ETLTool nvread 5082 >> nvwritelog.txt
ETLTool nvread 5083 >> nvwritelog.txt
ETLTool nvread 5084 >> nvwritelog.txt
ETLTool nvread 5085 >> nvwritelog.txt
ETLTool nvread 5086 >> nvwritelog.txt
ETLTool nvread 5087 >> nvwritelog.txt
ETLTool nvread 1190 >> nvwritelog.txt
ETLTool nvread 1894 >> nvwritelog.txt
ETLTool ping
ETLTool efs-get prim /sd/mru001 264 >> nvwritelog.txt
echo "============= MRU_Write_BEAR END ==============" >> nvwritelog.txt
cat nvwritelog.txt >> MRU_Write_BEAR.txt
cat nvwritelog.txt
echo "DONE......."
