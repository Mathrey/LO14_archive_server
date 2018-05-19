#!/bin/bash

function usage() {
	echo "Wrong input"
	exit -1
}

echo -e "\nserver.sh should be running at this point\n"
echo "Reminder :"
echo "vsh -list [SERVER_NAME] [PORT]"
echo "vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
echo "vsh -extract [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
echo -e "For a local server name should be localhost\n"


read -p "Waiting for vsh input... " input

#MODE=$(echo $input | cut -d" " -f2)
SERVER_NAME=$(echo $input | cut -d" " -f3)
PORT=$(echo $input | cut -d" " -f4)

echo -e "Server name : ${SERVER_NAME}"
echo -e "Port number : ${PORT}\n"

if (echo $PORT | grep -E -q "^[0-9]+$")
then
	echo "Client is running..."
	nc $SERVER_NAME $PORT < $input

fi


