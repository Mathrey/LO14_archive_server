#!/bin/bash

currentArchive=$(cat ../archives/$4)
currentDirectory=/

echo "vsh:> "
while read input
do
	set -- $(echo $input)
	echo $2
	echo $#
	case $1 in
		"pwd" )
		echo $currentDirectory
		;;

		"ls" )
		echo "commande ls"
		;;

		"cd" )
		echo "commande cd"
		;;

		"cat" )
		echo "commande cat"
		;;

		"rm" )
		echo "commande rm"
		;;

		* )
		echo "unknown command"
	esac
	echo "vsh:> "
done
