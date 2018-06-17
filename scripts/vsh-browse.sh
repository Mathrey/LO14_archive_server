#!/bin/bash

# BUG : supprime toutes entités qui ont le même nom, peu importe là où ils sont

# Ferme le client si l'utilisateur a oublié de mettre l'archive
if [ -z $4 ]
then
	echo "No archive given"
	echo "Usage : vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
	exit 1
fi

# Fonction récurrente permettant de supprimer un dossier
#arguments : $1=$toDeleteName (A; A1; ...) $2=$toDeletePath (/; /A; /A/A1; ...) (où se trouve le dossier) $3=$toDeleteContent $4=$toDeleteFile
function deleteDirectory() {

	# Début de la fonction
	#pathToDelete="$4"
	#echo $pathToDelete
	echo "test"
	echo "$1"
	echo "$2"
	echo "$3"
	echo "$4"
	# BUG : i contient toutes les lignes de $3
	# FIX : for i in "$3" -> for i in $3
	for i in $3
	do
		echo "Suppression de $i"	
		iName=$(echo "$i" | cut -d" " -f1)
		echo "$iName contenu dans $1"
		if (echo "$3" | egrep -q "^${iName} d")
		then
			if [ "$2" = "/" ]	
			then
				iPath=$(echo "$2$1/$iName")
				iPathParent=$(echo "$2$1")
				echo "test1 $iPath $iPathParent"
			else
				iPath=$(echo "$2/$1/$iName")
				iPathParent=$(echo "$2/$1")
				echo "test2 $iPath $iPathParent"
			fi
			echo "bonjour"
			echo "$root$iPath"
			iContent=$(echo "$currentArchive" | awk -v directory="$root$iPath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
			echo "$iName est un dossier dans $iPathParent"
			echo -e "$iName contient :\n$iContent"
			if [ -n "$iContent" ]
			then	
				deleteDirectory $iName $iPathParent $iContent $i
			else
				echo "$iName est vide, suppression en cours"
				# Suppression de directory $root$toDeletePath$toDeleteName
				#(cas où le dossier est à la racine)
				if (echo "$currentArchive" | egrep "^directory $root$iPath$")
				then
					currentArchive=$(echo "$currentArchive" | sed "s:^directory ${root}${iPath}$::")
					echo "directory $root$iPath$iName supprimé"
				#(cas où le dossier n'est pas à la racine)
				elif (echo "$currentArchive" | egrep "^directory $root$iPath/$iName$")
				then
					echo "suppression de : $root$iPath"
					currentArchive=$(echo "$currentArchive" | sed "s:^directory ${root}${iPath}$::")
					echo "directory $root$iPath supprimé"
				fi
				# Suppression de $toDeleteFile
				currentArchive=$(echo "$currentArchive" | sed "s/${i}//")
				echo "$i supprimé"
				echo "$currentArchive"
			fi
		else
			if [ "$2" = "/" ]	
			then
				iPath=$(echo "$2$1")
				echo "test1 $iPath"
			else
				iPath=$(echo "$2/$1")
				echo "test2 $iPath"
			fi
 
			echo "$iName est un fichier dans $iPath"	
			# On supprime le fichier
			# Récupération du contenu du fichier
			iDeleteFile=$(echo "$3" | egrep "^$iName [^d]")
			echo "$iDeleteFile"
			# Récupération ligne de début du contenu
			iDeleteBegin=$(echo "$iDeleteFile" | cut -d" " -f4)
			echo "begin at $iDeleteBegin"
			iDeleteBegin=$((iDeleteBegin+bodyBegin-1))
			echo "in archive begins at $iDeleteBegin"
			# Récupération longueur
			iDeleteLength=$(echo "$iDeleteFile" | cut -d" " -f5)
			echo "$iDeleteLength line(s) long"
			# Calcul ligne de fin
			iDeleteEnd=$((iDeleteBegin+iDeleteLength-1))
			echo "end at $iDeleteEnd"
			# Suppression fichier (header)
			currentArchive=$(echo "$currentArchive" | sed "s/${i}//")
			# Suppression fichier (body)
			currentArchive=$(echo "$currentArchive" | sed "${iDeleteBegin},${iDeleteEnd}s/.*//")
			echo "$iName supprimé"
		fi
	done
	echo "Contenu de $1 supprimé"

	# Suppression de directory $root$toDeletePath
	#(cas où le dossier est à la racine)
	echo "Suppression de ^directory $root$2$1$"
	if (echo "$currentArchive" | egrep "^directory $root$2$1$")
	then
		currentArchive=$(echo "$currentArchive" | sed "s:^directory $root$2$1$::")
		echo "suppression de : $root$2$1"
	#(cas où le dossier n'est pas à la racine)
	elif (echo "$currentArchive" | egrep "^directory $root$2/$1$")
	then
		echo "suppression de : $root$2/$1"
		currentArchive=$(echo "$currentArchive" | sed "s:^directory ${root}${2}/${1}$::")
	fi
	#  

	# Suppression de $toDeleteFile
	currentArchive=$(echo "$currentArchive" | sed "s:${4}::")
	echo "$currentArchive"

#dans la fonction :
#----pour tout le contenu du dossier :
#--------si dossier, on lance la fonction, le dossier et son contenu est supprimé
#--------si fichier, on supprime
#----supprimer le dossier
#le dossier et son contenu on été supprimé
	
}

## Variables locales
# Récupère le fichier texte de l'archive
currentArchive=$(cat ../archives/$4)
# currentDirectory ne doit jamais finir par "/" sauf lorsqu'on est à la racine
currentDirectory=/
# Récupère la racine de l'archive. Pour archive1 par exemple, $root a la valeur : Exemple/Test
root=$(echo "$currentArchive" | head -n 3 | tail -n 1 | cut -d" " -f2 | sed 's/\/$//')
# Numéro de ligne de début du head. Pour archive1 par exemple, $bodyBegin a la valeur : 3
headBegin=$(echo "$currentArchive" | head -n 1 | cut -d":" -f1)
# Numéro de ligne de début du body. Pour archive1 par exemple, $bodyBegin a la valeur : 25 
bodyBegin=$(echo "$currentArchive" | head -n 1 | cut -d":" -f2)

echo "Use pwd, ls, cd, cat and rm as usual"
echo -n "vsh:> "
# Tant que l'utilisateur ne quitte pas le programme
while read input
do
	# On change les arguments pour les gérer avec $1 $2 etc.
	set -- $(echo $input)
	echo "$1"
	case "$1" in

		# Affiche le dossier courant
		"pwd" )
		echo "$currentDirectory"
		;;

		# Affiche les fichiers et dossiers présents dans le dossier courant
		"ls" )

		# Récupérer la ligne dans le header correspondant au fichier courant ainsi que les lignes suivantes jusqu'au prochain @
		directoryContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')

		# On sauvegarde IFS et on le change pour la boucle for
		oldIFS=$IFS
		IFS=$'\n'

		# Pour chaque ligne dans le dossier courant, on affiche le nom, / à la fin si dossier, * à la fin si exécutable
		for i in $directoryContent
		do
			name=$(echo "$i" | cut -d" " -f1)
			perm=$(echo "$i" | cut -d" " -f2)
			# On vérifie s'il les permissions commencent par un d
			if (echo "$perm" | egrep -q "^d")
			then
				echo -ne "$name/\t"
			# Sinon on vérifie s'il y a un x dans les permissions
			elif (echo "$perm" | egrep -q "x")
			then
				echo -ne "$name*\t"
			else
				echo -ne "$name\t"
			fi
		done
		echo ""
		# Restauration de IFS
		IFS=$oldIFS
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
			# UPDATE : il y a un espace après A/A2 et A/A3
			# FIX : ajouter " ?$" à la fin de la régex pour gérer la présence d'un possible espace
			# FIX : suppression des espaces aux endroits où ils n'ont pas lieu d'être
			if (echo "$currentArchive" | egrep -q "^directory $root$path ?$")
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
					echo "No directory found"
					currentDirectory=/
				else
					# On revient au dossier précédent grâce au chemin
					currentDirectory=$(echo "$currentDirectory" | egrep -o ".*/")
					# Si on n'est pas revenu à la racine on retire le "/" de fin
					if [ "$currentDirectory" != "/" ]
					then
						# On enlève le "/" à la fin pour rester cohérent
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
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory$path ?$")
					then
						# Pas besoin de rajouter un "/" entre l'origine et la destination
						currentDirectory=$(echo "$currentDirectory$path")
					else
						echo "No directory found"
					fi
				# Si on est ailleurs qu'à la racine
				else
					# Si le chemin est présent dans l'archive
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory/$path ?$")
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

		# Affiche le contenu du fichier donné en entrée
		"cat" )

		toprompt=$2
		echo $toprompt

		if [[ -n "$toprompt" ]]
			then
				# On trouve la ligne de l'archive des lignes de début et fin du contenu inscrit dans body
				sed -e "^$toprompt "

			else
				echo "No file in argument to prompt"
			fi
		;;

		# Supprime un fichier/dossier
		"rm" )
		toDelete=$2

		if [ -n "$toDelete" ]
		then
			# On retire le possible "/" à la fin d'un chemin (sauf si c'est la racine)
			if (echo "$toDelete" | egrep -q ".+/$")
			then
				toDelete=$(echo "$toDelete" | sed 's/.$//')
	                fi

			# Chemin absolu
			if (echo "$toDelete" | egrep -q "^/")
			then
				# Si l'entité est la racine
				if [ "$toDelete" = "/" ]
				then
					echo "Are you sure you want to delete everything ? y/n"
					read response
					case $response in

						[yYoO]*)
						currentArchive=''
						;;

						[nN]*)
						echo "Deletion aborted"
						;;

						*)
						echo "Incorrect response"
					esac
				else
					# On récupère le chemin de l'entité à supprimer (-o ne print que les matchs) sous la forme A/A1 ou A
					toDeletePath=$(echo "$toDelete" | egrep -o ".*/") 
					if [ $toDeletePath != "/" ]
					then
						toDeletePath=$(echo "$toDeletePath" | sed "s/\/$//")
					fi 

					# On recupére le nom de l'entité à supprimer
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")
					# On récupère le contenu du chemin de l'entité
					toDeletePathContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')

					# On vérifie que le chemin est un directory : l'entité est un dossier (cas où le dossier est à la racine)
					if (echo "$currentArchive" | egrep "^directory $root$toDeletePath$toDeleteName ?$")
					then
						echo "Directory found in $toDeletePath"
						toDeleteFile=$(echo "$toDeletePathContent" | egrep "^$toDeleteName d")
						echo "Ligne du fichier dans l'archive : $toDeleteFile"
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						echo "In this directory :"
						echo "$toDeleteContent"
						# On sauvegarde IFS et on le change pour la boucle for
						oldIFS=$IFS
						IFS=$'\n'
						deleteDirectory $toDeleteName "$toDeletePath" "$toDeleteContent" "$toDeleteFile"
						# Restauration de IFS
						IFS=$oldIFS

					# On vérifie que le chemin est un directory : l'entité est un dossier (cas où le dossier n'est pas à la racine)
					elif (echo "$currentArchive" | egrep "^directory $root$toDeletePath/$toDeleteName ?$")
					then
						echo "Directory found in $toDeletePath"
						toDeleteFile=$(echo "$toDeletePathContent" | egrep "^$toDeleteName d")
						echo "Ligne du fichier dans l'archive : $toDeleteFile"
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath/$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						echo "In this directory :"
						echo "$toDeleteContent"
						# On sauvegarde IFS et on le change pour la boucle for
						oldIFS=$IFS
						IFS=$'\n'
						deleteDirectory $toDeleteName "$toDeletePath" "$toDeleteContent" "$toDeleteFile"
						# Restauration de IFS
						IFS=$oldIFS

					# On vérifie que le nom existe et que les permissions ne commencent pas par d : l'entité est un fichier
					elif (echo "$toDeletePathContent" | egrep "^$toDeleteName [^d]")
					then
						echo "$toDeleteName found"
						# Récupération du contenu du fichier
						toDeleteFile=$(echo "$currentArchive" | egrep "^$toDeleteName [^d]")
						echo "in archive $toDeleteFile"
						# Récupération ligne de début du contenu
						toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)
						echo "begin at $toDeleteBegin"
						toDeleteBegin=$((toDeleteBegin+bodyBegin-1))
						echo "in archive begins at $toDeleteBegin"
						# Récupération longueur
						toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)
						echo "$toDeleteLength line(s) long"
						# Calcul ligne de fin
						toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))
						echo "end at $toDeleteEnd"
						# Suppression fichier (headder)
						currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
						# Suppression fichier (body)
						currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
						echo "File deleted"
						echo "$currentArchive"
					else
						echo "No directory or file found"
					fi
				fi
			# Chemin relatif
			else
				echo "Chemin relatif"
				echo "$currentDirectory"
				
				if (echo "$toDelete" | egrep -q "/")
				# On souhaite supprimer dans un dossier fils
				then
					echo "Child directory"
					# On récupère le chemin de l'entité à supprimer
					if [ "$currentDirectory" = "/" ]
					then
						toDeletePath=$(echo "/$toDelete" | sed -r 's/(\/[^\/]+)$//')
					else
						toDeletePath=$(echo "$currentDirectory/$toDelete" | sed -r 's/(\/[^\/]+)$//')
					fi

					echo "path = $toDeletePath"
					# On recupére le nom de l'entité à supprimer
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")
					echo "name of file = $toDeleteName"

					# On regarde si le chemin existe
					if (echo "$currentArchive" | egrep "^directory $root$toDeletePath$")
					# On regarde si le fichier/dossier est dans le contenu du dossier	
					then
						echo "$toDeletePath existe dans $currentDirectory"
						
						currentContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						echo "Contenu du dossier courant : $currentContent"
						# On regarde si l'entité existe dans le contenu de ce chemin et est un fichier
						if (echo "$currentContent" | egrep "^$toDeleteName [^d]")
						then
							echo "$toDeleteName est bien un fichier dans $toDeletePath"
							# On supprime le fichier
							# Récupération du contenu du fichier
							toDeleteFile=$(echo "$currentContent" | egrep "^$toDeleteName [^d]")
							echo "in archive $toDeleteFile"
							# Récupération ligne de début du contenu
							toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)
							echo "begin at $toDeleteBegin"
							toDeleteBegin=$((toDeleteBegin+bodyBegin-1))
							echo "in archive begins at $toDeleteBegin"
							# Récupération longueur
							toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)
							echo "$toDeleteLength line(s) long"
							# Calcul ligne de fin
							toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))
							echo "end at $toDeleteEnd"
							# Suppression fichier (header)
							currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
							# Suppression fichier (body)
							currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
							echo "File deleted"
							echo  "$currentArchive"
						# On regarde si l'entité existe dans le contenu de ce chemin et est un dossier
						elif (echo "$currentContent" | egrep -q "^$toDeleteName [d]")
						then
							echo "$toDeleteName est bien un dossier dans $toDeletePath"
						# NOT-OK
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath/$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						toDeleteFile=$(echo "$currentContent" | egrep "^$toDeleteName [d]")

						# On sauvegarde IFS et on le change pour la boucle for
						oldIFS=$IFS
						IFS=$'\n'
						deleteDirectory $toDeleteName "$toDeletePath" "$toDeleteContent" "$toDeleteFile"
						# Restauration de IFS
						IFS=$oldIFS
						else
							echo "No file or directory found there"
						fi
					else
						echo "No such path found"
						echo "$root$currentDirectory/?$toDeletePath"
					fi

				# On souhaite supprimer dans le dossier courant
				else
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")
					echo "name of file = $toDeleteName"

					# On liste le contenu du dossier courant
					currentContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
					echo "found in $currentDirectory with these :"
					echo "$currentContent"

					# On gère le chemin du fichier à supprimer selon qu'on soit à la racine ou non
					if [ "$currentDirectory" = "/" ]
					then
						#toDeletePath=$(echo "$toDelete" | sed -r 's/(\/[^\/]+)$//')
						toDeletePath="$currentDirectory"
						echo "Chemin du fichier à supprimer si on est à la racine : $toDeletePath"
					else
						# BUG : toDeletePath ne prend pas la valeur lorsque que l'on rajoute le sed
						# FIX : Faire en deux fois de sorte à ne pas se faire piéger par l'expression linéaire qui renvoie tout ce qu'il y a avant le dernier "/" (donc rien si le seul "/" est le premier caractère)
						#toDeletePath=$(echo "$toDelete" | sed -r 's/(\/[^\/]+)$//')
						toDeletePath=$(echo "$currentDirectory")
						echo "Chemin du fichier à supprimer si on n'est pas à la racine : $toDeletePath"
					fi

					# On vérifie que l'entité existe et est un dossier
					if (echo "$currentContent" | egrep -q "^$toDeleteName d")
					then
							if [ $currentDirectory = "/" ]
							then							
								echo "Directory found"
								toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
								echo "$root$toDeletePath"
								echo "In this directory :"
								echo "$toDeleteContent"
								toDeleteFile=$(echo "$currentContent" | egrep "$toDeleteName d")
								# On sauvegarde IFS et on le change pour la boucle for
								oldIFS=$IFS
								IFS=$'\n'
								deleteDirectory $toDeleteName $toDeletePath "$toDeleteContent" "$toDeleteFile"
								# Restauration de IFS
								IFS=$oldIFS

							# BUG : ne liste pas le bon contenu du dossier à supprimer lorsque l'on n'est pas à la racine (liste le dossier courant à la place)
							# FIX : gérer le cas où l'on est à la racine pour la variable $toDeletePath
							else
								echo "Directory found"
								toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath/$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
								echo "$root$toDeletePath"
								echo "In this directory :"
								echo "$toDeleteContent"
								toDeleteFile=$(echo "$currentContent" | egrep "$toDeleteName d")
								# On sauvegarde IFS et on le change pour la boucle for
								oldIFS=$IFS
								IFS=$'\n'
								deleteDirectory $toDeleteName $toDeletePath "$toDeleteContent" "$toDeleteFile"
								# Restauration de IFS
								IFS=$oldIFS
							fi

					# On vérifie que le nom existe dans le dossier courant et que les permissions ne commencent pas par d : l'entité est un fichier
					elif (echo "$currentContent" | egrep "^$toDeleteName [^d]")
					then
						echo "$toDelete found"
						# Récupération du contenu du fichier
						toDeleteFile=$(echo "$currentArchive" | egrep "^$toDeleteName [^d]")
						echo "in archive $toDeleteFile"
						# Récupération ligne de début du contenu
						toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)
						echo "begin at $toDeleteBegin"
						toDeleteBegin=$((toDeleteBegin+bodyBegin-1))
						echo "in archive begins at $toDeleteBegin"
						# Récupération longueur
						toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)
						echo "$toDeleteLength line(s) long"
						# Calcul ligne de fin
						toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))
						echo "end at $toDeleteEnd"
						# Suppression fichier (header)
						currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
						# Suppression fichier (body)
						currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
						echo "File deleted"
						#echo "$currentArchive"
					else
						echo "No directory or file found"
						
					fi
					
				fi

			fi
		else
			echo "No file to delete"
		fi
		;;

		* )
		echo "unknown command"
	esac
	set -- $(echo $input)
	echo -n "vsh:> "
done
