#!/bin/bash

function usage() {
	echo "Wrong input"
	exit -1
}

echo ""
echo "server.sh should be running at this point"
echo ""
echo "Reminder :"
echo "vsh -list [SERVER_NAME] [PORT]"
echo "vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
echo "vsh -extract [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
echo "For a local server name should be localhost"
echo ""

read -p "Waiting for vsh input... " input

#MODE=$(echo $input | cut -d" " -f2)
SERVER_NAME=$(echo $input | cut -d" " -f3)
PORT=$(echo $input | cut -d" " -f4)

echo $SERVER_NAME
echo $PORT

if (echo $PORT | grep -E -q "^[0-9]+$")
then
	echo "Client is running..."
#	echo $input | nc $SERVER_NAME $PORT

fi


