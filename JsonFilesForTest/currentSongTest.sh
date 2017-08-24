#!/bin/bash -x

DIR=`pwd`
FILE1="$DIR/Sunrise Avenue - Hollywood Hills.mp3"
FILE2="$DIR/Across The Sun - The Sun Sets.mp3"

echo "OPENED $FILE1" | nc localhost 9999
sleep 5
echo "OPENED $FILE2" | nc localhost 9999
sleep 5
echo "CLOSED $FILE1" | nc localhost 9999
sleep 5
echo "PLAYING $FILE2" | nc localhost 9999
sleep 5
echo "CLOSED $FILE2" | nc localhost 9999



