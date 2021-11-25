echo "============= MRU_Write_ICA =============="
ETLTool USB ping > nvwritelog.txt
ETLTool USB ping
ETLTool USB ping
echo "============= MRU_Write_ICA Begin ==============" >> nvwritelog.txt
date >> nvwritelog.txt
echo "[ Before Write ] " >> nvwritelog.txt
ETLTool USB nvread 945 >> nvwritelog.txt
ETLTool USB nvwrite 945 0 2 1 32 00 57 10 57

ETLTool USB nvread 722 >> nvwritelog.txt
ETLTool USB nvwrite 722 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
ETLTool USB nvread 723 >> nvwritelog.txt
ETLTool USB nvwrite 723 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool USB nvread 737 >> nvwritelog.txt
ETLTool USB nvwrite 737 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool USB nvread 738 >> nvwritelog.txt
ETLTool USB nvwrite 738 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool USB nvread 739 >> nvwritelog.txt
ETLTool USB nvwrite 739 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00000000 0 0x00000000 0x00000000 0x00000000 0x00000000
ETLTool USB nvread 5080 >> nvwritelog.txt
ETLTool USB nvwrite 5080 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5081 >> nvwritelog.txt
ETLTool USB nvwrite 5081 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5082 >> nvwritelog.txt
ETLTool USB nvwrite 5082 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5083 >> nvwritelog.txt
ETLTool USB nvwrite 5083 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5084 >> nvwritelog.txt
ETLTool USB nvwrite 5084 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5085 >> nvwritelog.txt
ETLTool USB nvwrite 5085 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5086 >> nvwritelog.txt
ETLTool USB nvwrite 5086 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 5087 >> nvwritelog.txt
ETLTool USB nvwrite 5087 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ETLTool USB nvread 1190 >> nvwritelog.txt
ETLTool USB nvwrite 1190 0x00 0x00
ETLTool USB nvread 1894 >> nvwritelog.txt
ETLTool USB nvwrite 1894 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
echo "[ After Write ] " >> nvwritelog.txt
ETLTool USB nvread 945 >> nvwritelog.txt
ETLTool USB nvread 722 >> nvwritelog.txt
ETLTool USB nvread 723 >> nvwritelog.txt
ETLTool USB nvread 737 >> nvwritelog.txt
ETLTool USB nvread 738 >> nvwritelog.txt
ETLTool USB nvread 739 >> nvwritelog.txt
ETLTool USB nvread 5080 >> nvwritelog.txt
ETLTool USB nvread 5081 >> nvwritelog.txt
ETLTool USB nvread 5082 >> nvwritelog.txt
ETLTool USB nvread 5083 >> nvwritelog.txt
ETLTool USB nvread 5084 >> nvwritelog.txt
ETLTool USB nvread 5085 >> nvwritelog.txt
ETLTool USB nvread 5086 >> nvwritelog.txt
ETLTool USB nvread 5087 >> nvwritelog.txt
ETLTool USB nvread 1190 >> nvwritelog.txt
ETLTool USB nvread 1894 >> nvwritelog.txt
ETLTool USB ping
cat nvwritelog.txt >> MRU_Write_ICA.txt
cat nvwritelog.txt
