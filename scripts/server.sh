#!/bin/bash

function usage {
	echo "Usage : $(basename $0) PORT_NUMBER"
	exit -1
}

if (test $# -eq 1) && (echo $1 | grep -E -q "^[0-9]+$") # teste si 1 argument et si c'est des chiffres
then
	#nc -lp $1 -e vsh
	echo "it works !"
else
	usage
fi
