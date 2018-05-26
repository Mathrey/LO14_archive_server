#!/bin/bash

#if $4 is empty then echo "pas d'archive entrée" exit 1
#si le temps le permet :
#gérer cd .. ; cd ../../../../ ... ;

if [ -z $4 ]
then
	echo "No archive given"
	echo "Usage : vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
	exit 1
fi

currentArchive=$(cat ../archives/$4)
currentDirectory=/
root=$(echo "$currentArchive" | head -n 3 | tail -n 1 | cut -d" " -f2 | sed 's/\/$//') #Récupère la racine de l'archive

echo -n "vsh:> "
while read input
do
	set -- $(echo $input)
	case $1 in

		# Affiche le dossier courant
		"pwd" )
		echo "$currentDirectory"
		;;

		# Affiche les fichiers et dossiers présents dans le dossier courant
		"ls" )
		
		;;

		# Permet de changer de répertoire
		"cd" )
		path=$2

		# On retire le "/" à la fin du chemin
		if (echo "$path" | egrep -q "/$")
		then
			path=$(echo "$path" | sed 's/.$//')
		fi

		# On teste si chemin absolu ou relatif
		if (echo "$path" | egrep -q "^/")
		# Chemin absolu
		then
			# Note : il y a un bug lorsque l'on rajoute "$" à la fin de la régex, tous les dossiers sont trouvés sauf /A/A2 et /A/A3
			if (echo "$currentArchive" | egrep -q "^directory $root$path")
			then
				currentDirectory=$(echo "$path")
			else
				echo "No directory found"
			fi
		# Chemin relatif
		else
			if [ -z "$path" ]
			then
				currentDirectory=/
			elif [ "$path" = ".." ]
			then
				if [ "$currentDirectory" = "/" ]
				then
					currentDirectory=/
				else
					currentDirectory=$(echo "$currentDirectory" | egrep -o ".*/")
					if [ "$currentDirectory" != "/" ]
					then
						currentDirectory=$(echo "$currentDirectory" | sed 's/\/$//')
					fi
				fi
			else
				if [ "$currentDirectory" = "/" ]
				then
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory$path")
					then
						currentDirectory=$(echo "$currentDirectory$path")
					else
						echo "No directory found"
					fi
				else
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory/$path")
					then
						currentDirectory=$(echo "$currentDirectory/$path")
					else
						echo "No directory found"
					fi
				fi
			fi
		fi
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
	echo -n "vsh:> "
done

