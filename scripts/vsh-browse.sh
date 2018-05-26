#!/bin/bash

# Ferme le client si l'utilisateur a oublié de mettre l'archive
if [ -z $4 ]
then
	echo "No archive given"
	echo "Usage : vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
	exit 1
fi

# Variables locales
currentArchive=$(cat ../archives/$4)
currentDirectory=/
root=$(echo "$currentArchive" | head -n 3 | tail -n 1 | cut -d" " -f2 | sed 's/\/$//') #Récupère la racine de l'archive

echo -n "vsh:> "
# Tant que l'utilisateur ne quitte pas le programme
while read input
do
	# On change les arguments pour les gérer avec $1 $2 etc.
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

		# On retire le possible "/" à la fin d'un chemin (sauf si cd /)
		if (echo "$path" | egrep -q "/$")
		then
			path=$(echo "$path" | sed 's/.$//')
		fi

		# On teste si chemin absolu ou relatif
		if (echo "$path" | egrep -q "^/")
		# Chemin absolu
		then
			# On vérifie que le chemin est présent dans l'archive
			# BUG : il y a un bug lorsque l'on rajoute "$" à la fin de la régex, tous les dossiers sont trouvés sauf /A/A2 et /A/A3, le grep récupère donc tous les résultats où le chemin apparaît (ce qui ne gêne pas puisqu'on veut juste vérifier qu'il existe)
			# FIX : enlever le $ à la fin de la régex
			if (echo "$currentArchive" | egrep -q "^directory $root$path")
			then
				currentDirectory=$(echo "$path")
			else
				echo "No directory found"
			fi
		# Chemin relatif
		else
			# Si cd
			if [ -z "$path" ]
			then
				currentDirectory=/
			# Si cd ..
			elif [ "$path" = ".." ]
			then
				# Si on est déjà à la racine
				if [ "$currentDirectory" = "/" ]
				then
					currentDirectory=/
				else
					currentDirectory=$(echo "$currentDirectory" | egrep -o ".*/")
					# Si on n'est pas revenu à la racine on retire le "/" de fin
					if [ "$currentDirectory" != "/" ]
					then
						currentDirectory=$(echo "$currentDirectory" | sed 's/\/$//')
					fi
				fi
			# Si cd Dossier/Dossier1 etc.
			else
				# À cause des "/", on traite différemment la ligne de texte selon que l'on soit sur la racine ou non
				# Si on est dans la racine
				if [ "$currentDirectory" = "/" ]
				then
					# Si le chemin est présent dans l'archive
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory$path")
					then
						# Pas besoin de rajouter un "/" entre l'origine et la destination
						currentDirectory=$(echo "$currentDirectory$path")
					else
						echo "No directory found"
					fi
				# Si on est ailleurs qu'à la racine
				else
					# Si le chemin est présent dans l'archive
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory/$path")
					then
						# On ajoute le "/" entre l'origine et la destination
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

