#!/bin/bash


echo "server.sh should be running at this point"
echo "Reminder :"
echo "vsh -list [SERVER_NAME] [PORT]"
echo "vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
echo "vsh -extract [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
echo "For local server name should be localhost"

read input?"Waiting for vsh input..."

local $MODE = cut -f input 1

if (test $# -eq 1) && (echo $1 | grep -E -q "^[0-9]+$")
then
	#nc localhost $1
	echo "Client is running"
else
	usage
fi


