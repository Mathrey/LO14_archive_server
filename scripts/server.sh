#!/bin/bash

# Fonction de rappel de l'utilisation du script
function usage {
	echo "Usage : $0 PORT_NUMBER"
	exit -1
}

# Création du dossier tmp pour les interactions entre serveur et client
if [ ! -e "./tmp" ]
then
	mkdir ./tmp
	echo "tmp/ created"
fi

# Fonction de nettoyage du dossier
function nettoyage() { rm -f tmp/tube ; rm -f tmp/request.txt ; }
# Lance nettoyage lorsque que le programme est quitté
trap nettoyage EXIT

# Pour chaque cas :
# On crée le tube nommé s'il n'existe pas avec mkfifo
# On remplit le tube avec l'output de la fonction vsh correspondante et on envoie le contenu du tube sur la connexion
# On supprime le tube

function vsh() {
	case $1 in

		"-list" )
		echo "list mode requested @ "$(date +%T)
		[ -e tmp/tube ] || mkfifo tmp/tube
		nc -lp $3 < tmp/tube | bash ./vsh-list.sh args currentDirectory > tmp/tube
		echo "request sent @ "$(date +%T)
		rm tmp/tube
		;;

		"-extract" )
		echo "mode extract requested (but not yet functionnal)"
		[ -e tmp/tube ] || mkfifo tmp/tube
#		nc -lp $3 < tmp/tube | bash ./vsh-extract.sh args > tmp/tube
		nc -lp $3 < tmp/tube | echo "extract mode not yet implemented" > tmp/tube
		rm tmp/tube
		;;

		"-browse" )
		echo "mode browse requested (but not yet functionnal)"
		[ -e tmp/tube ] || mkfifo tmp/tube
#		nc -lp $3 < tmp/tube | bash ./vsh-browse.sh args > tmp/tube
		nc -lp $3 < tmp/tube | echo "browse mode not yet implemented" > tmp/tube
		rm tmp/tube
		;;

		* )
		echo "wrong request"
		[ -e tmp/tube ] || mkfifo tmp/tube
		nc -lp $3 < tmp/tube | echo "this mode does not exist"
		rm tmp/tube
		;;
	esac
}

# Vérifie que le seul argument au lancement est un nombre
if (test $# -eq 1) && (echo $1 | grep -E -q "^[0-9]+$")
then
	echo -e "\nit works !\n"
else
	usage
fi

# Le serveur tourne
while true; do
	echo "waiting input from client"
# Écrit la réception sur le port $1 dans le fichier input.txt
	nc -lp $1 > tmp/request.txt
	echo "input done !"
# Associe le fichier input récupéré dans la variable input
#	input=$(cat tmp/request.txt)
	request=$(sed -n '1p' tmp/request.txt)
	currentDirectory=$(sed -n '2p' tmp/request.txt)
# Lit input et convertit en commande/arguments
	read cmd args <<< $(echo $request)
# Lance vsh avec les arguments si reconnu
	if [ "$(type -t $cmd)" = "function" ]; then
		$cmd $args $currentDirectory
	else
		echo "command unknown"
	fi
done
