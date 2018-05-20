#!/bin/bash

# Fonction de rappel de l'utilisation du script
function usage {
	echo "Usage : $0 PORT_NUMBER"
	exit -1
}

# Création du tube nommé pour les interactions entre serveur et client
if [ ! -e "./tmp" ]
then
	mkdir ./tmp
	echo "FIFO created"
fi

FIFO="./tmp/FIFO"

# Fonction de nettoyage du dossier
function nettoyage() { rm -f "$FIFO"; }
# Lance nettoyage lorsque que le programme est quitté
trap nettoyage EXIT

# Créer le tube nommé FIFO si le fichier FIFO n'existe pas
[ -e "$FIFO" ] || mkfifo "$FIFO"

# Fonction qui renvoie aux fonctions de vsh
# Ne marche pas, à revoir
#function readinput() {
#	local cmd args
#	while true; do
#		read cmd args || exit -1
#		fun="commande-$cmd"
#		if [ "$(type -t $fun)" = "function" ]; then
#			$fun $args
#		else
#			echo "Unknown command"
#		fi
#	done
#}

function vsh() {
	case $1 in
		"-list" )
		echo "mode list activated"
		bash ./vsh-list.sh args
		;;

		"-extract" )
		echo "mode exctract activated"
		#bash vsh-extract.sh args
		;;

		"-browse" )
		echo "mode browse activated"
		#bash vsh-browse.sh args
		;;

		* )
		echo "unknown mode"
		;;
	esac
}

# Vérifie que le 1er argument est un nombre
if (test $# -eq 1) && (echo $1 | grep -E -q "^[0-9]+$")
then
	echo -e "\nit works !\n"
else
	usage
fi

# Partie serveur
while true; do
	echo "waiting input"
# Écrit la réception dans le dossier FIFO
#	nc -lp $1 > "$FIFO"
	echo "input done !"
done
