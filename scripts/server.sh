#!/bin/bash

# Fonction de rappel de l'utilisation du script
function usage {
	echo "Usage : $0 PORT_NUMBER"
	exit -1
}

# Création du tube nommé pour les interactions entre serveur et client
FIFO="./tmp/FIFO"

# Fonction de nettoyage du dossier
function nettoyage() { rm -f "$FIFO"; }
# Lance nettoyage lorsque que le programme est quitté
trap nettoyage EXIT

# Créer le tube nommé FIFO si le fichier FIFO n'existe pas
[ -e "$FIFO" ] || mkfifo "$FIFO"

# Vérifie que le 1er argument est un nombre
if (test $# -eq 1) && (echo $1 | grep -E -q "^[0-9]+$")
then
	echo -e "\nit works !\n"
else
	usage
fi

# Fonction qui renvoie aux fonctions de vsh
function interaction() {
	local cmd args
	while true; do
		read cmd args || exit -1
		if [ "$(type -t $cmd)" = "function" ]; then
			$cmd $args
		else
			echo "Unknown command"
		fi
	done
}

function vsh() {
	case $1 in
		"-list" )
		echo "mode list activated"
		#bash vsh-list.sh
		;;

		"-extract" )
		echo "mode exctract activated"
		#bash vsh-extract.sh
		;;

		"-browse" )
		echo "mode browse activated"
		#bash vsh-browse.sh
	esac
}


# Partie serveur
while true; do
	interaction < "$FIFO" | nc -lp $1 > "$FIFO"
done
