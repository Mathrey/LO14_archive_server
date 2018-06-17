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

	# BUG : i contient toutes les lignes de $3
	# FIX : for i in "$3" -> for i in $3
	for i in $3
	do	
		iName=$(echo "$i" | cut -d" " -f1)
		if (echo "$3" | egrep -q "^${iName} d")
		then
			if [ "$2" = "/" ]	
			then
				iPath=$(echo "$2$1/$iName")
				iPathParent=$(echo "$2$1")
			else
				iPath=$(echo "$2/$1/$iName")
				iPathParent=$(echo "$2/$1")
			fi
			iContent=$(echo "$currentArchive" | awk -v directory="$root$iPath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')

			if [ -n "$iContent" ]
			then	
				deleteDirectory $iName $iPathParent $iContent $i
			else
				# Suppression de la ligne directory $root$toDeletePath$toDeleteName
				# (cas où le dossier est à la racine)
				if (echo "$currentArchive" | egrep -q "^directory $root$iPath$")
				then
					currentArchive=$(echo "$currentArchive" | sed "s:^directory ${root}${iPath}$::")
				# (cas où le dossier n'est pas à la racine)
				elif (echo "$currentArchive" | egrep -q "^directory $root$iPath/$iName$")
				then
					currentArchive=$(echo "$currentArchive" | sed "s:^directory ${root}${iPath}$::")
				fi
				# Suppression de la ligne $toDeleteFile
				currentArchive=$(echo "$currentArchive" | sed "s/${i}//")
				echo "$iName supprimé"
			fi
		else
			if [ "$2" = "/" ]	
			then
				iPath=$(echo "$2$1")
			else
				iPath=$(echo "$2/$1")
			fi
	
			# On supprime le fichier
			# Récupération du contenu du fichier
			iDeleteFile=$(echo "$3" | egrep "^$iName [^d]")

			# Récupération ligne de début du contenu
			iDeleteBegin=$(echo "$iDeleteFile" | cut -d" " -f4)

			iDeleteBegin=$((iDeleteBegin+bodyBegin-1))

			# Récupération longueur
			iDeleteLength=$(echo "$iDeleteFile" | cut -d" " -f5)

			# Calcul ligne de fin
			iDeleteEnd=$((iDeleteBegin+iDeleteLength-1))

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

	if (echo "$currentArchive" | egrep -q "^directory $root$2$1$")
	then
		currentArchive=$(echo "$currentArchive" | sed "s:^directory $root$2$1$::")

	#(cas où le dossier n'est pas à la racine)
	elif (echo "$currentArchive" | egrep -q "^directory $root$2/$1$")
	then

		currentArchive=$(echo "$currentArchive" | sed "s:^directory ${root}${2}/${1}$::")
	fi

	# Suppression de $toDeleteFile
	currentArchive=$(echo "$currentArchive" | sed "s:${4}::")
	echo "$currentArchive"
	
}

function catfile(){

# la variable hdebut donne la ligne où commence le header de l'archive
hdebut=$(echo "$currentArchive" | sed '1q' | cut -d : -f 1) # head -n 1 | cut -d : -f 1)
# la variable bdebut donne la ligne où commence le body de l'archive
bdebut=$(echo "$currentArchive" | sed '1q' | cut -d : -f 2) 
# la variable hend donne la ligne où se termine le header de l'archive
hend=$(($bdebut-1)) 
# la variable bend donne la ligne où se termine le body de l'archive
bend=$(echo "$currentArchive" | sed -n '$=')
# On crée deux variables pour séparer les contenus du header et du body
header=$(echo "$currentArchive" | sed -n "$((hdebut)),$((hend))p")
body=$(echo "$currentArchive" | sed -n "$((bdebut)),$((bend))p")

# Dans la fonction principale, on a besoin de lire le header ligne par ligne
# Avec une boucle for, il faut donc changer temporairement le séparateur de champ
# pour que seul soit reconnu le saut de ligne

# Sauvegarde du séparateur de champ
old_IFS=$IFS 
# Nouveau séparateur de champ, le caractère fin de ligne
IFS=$'\n' 

# Fonction principale
# On teste si l'archive contient le fichier à afficher
if [[ $(echo "$header" | egrep "^${toPrompt}\s[^d]") ]]
	then
		for line in $header
			do
				# On trouve la ligne de l'archive indexant le fichier à présenter
				if [[ $(echo "$line" | egrep "^${toPrompt}\s[^d]") ]]
					then
						echo ""
						# On va affecter à des variables le nom et l'emplacement du contenu du fichier  :
						namef=$(echo "$line" | cut -d " " -f 1) 
							echo "Processing file $namef"
						fdebut=$(echo "$line" | cut -d " " -f 4)
							echo "Debut lign in archive body : $fdebut"
						flength=$(echo "$line" | cut -d " " -f 5)
							echo "Number of ligns in body : $flength"
						fend=$((fdebut+flength-1))
							echo "End lign in archive body : $fend"
						echo ""

						# Si la longueur du fichier vaut 0 il n'y a rien à afficher, mais il vaut mieux prévenir le client que cela est normal
						if [[ $flength -eq 0 ]]
							then
								echo "The file $namef is an empty file."
								echo ""					
							else	
								echo "The file $namef contains :"
								echo ""
								echo "$body" | sed -n "$((fdebut)),$((fend))p"
								echo ""
						fi
				fi 
			done
	else
		echo "You may have mistaken a directory for a file, or misspelled the name of the file."
		echo "Check again!"
fi

# Rétablissement du séparateur de champ par défaut
IFS=$old_IFS 

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
			# Si "cd "
			if [ -z "$path" ]
			then
				currentDirectory=/
			# Si "cd .."
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
			# Si cd "Dossier/..."
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

		toPrompt=$2
		echo $toPrompt

		if [[ -n "$toPrompt" ]]
			then
				# On retire le possible "/" à la fin d'un chemin (sauf si c'est la racine)
				if (echo "$toPrompt" | egrep -q ".+/$")
					then
						toPrompt=$(echo "$toPrompt" | sed 's/.$//')
						echo "The variable toPrompt : $toPrompt"
	       		fi

	       		# Chemin absolu
				if (echo "$toPrompt" | egrep -q "^/")
					then
						# Si l'entrée est la racine
						if [ "$toPrompt" = "/" ]
							echo "The root directory is not a file"

					else
						# On récupère le chemin du fichier à afficher (-o ne print que les matchs) sous la forme A/A1 ou A
						toPromptPath=$(echo "$toPrompt" | egrep -o ".*/")
						echo "The variable toPromptPath : $toPromptPath" 
						if [ $toPromptPath != "/" ]
							then
								toPromptPath=$(echo "$toPromptPath" | sed "s/\/$//")
								echo "The new variable toPromptPath : $toPromptPath"
						fi 

						# On recupére le nom de l'entité à afficher
						toPromptName=$(echo "$toPrompt" | egrep -o "[[:alnum:]]+$")
						echo "The variable toPromptName : $toPromptName"
						# On récupère le contenu du chemin de l'entité
						toPromptPathContent=$(echo "$currentArchive" | awk -v directory="$root$toPromptPath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						echo "The variable toPromptPathContent : $toPromptPathContent"
						
						# On vérifie que le chemin est un directory : l'entité est un dossier (cas où le dossier est à la racine)
						if (echo "$currentArchive" | egrep -q "^directory $root$toPromptPath$toPromptName ?$")
							then
								toPromptFile=$(echo "$toPromptPathContent" | egrep "^$toPromptName d")
								toPromptContent=$(echo "$currentArchive" | awk -v directory="$root$toPromptPath$toPromptName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
								echo "$toPromptName is a directory and cannot be prompt by cat"
								# On sauvegarde IFS et on le change pour la fonction récurrente
								# oldIFS=$IFS
								# IFS=$'\n'
								# deleteDirectory $toDeleteName "$toPromptPath" "$toPromptContent" "$toPromptFile"
								# Restauration de IFS
								# IFS=$oldIFS

						# On vérifie que le chemin est un directory : l'entité est un dossier (cas où le dossier n'est pas à la racine)
						elif (echo "$currentArchive" | egrep -q "^directory $root$toPromptPath/$toPromptName ?$")
							then
								toPromptFile=$(echo "$toPromptPathContent" | egrep "^$toPromptName d")
								toPromptContent=$(echo "$currentArchive" | awk -v directory="$root$toPromptPath/$toPromptName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
								echo "$toPromptName is a directory and cannot be prompt by cat"

								# On sauvegarde IFS et on le change pour la fonction récurrente
								# oldIFS=$IFS
								# IFS=$'\n'
								# deleteDirectory $toPromptName "$toPromptPath" "$toPromptContent" "$toPromptFile"
								# Restauration de IFS
								# IFS=$oldIFS

						# On vérifie que le nom existe et que les permissions ne commencent pas par d : l'entité est un fichier
						elif (echo "$toPromptPathContent" | egrep -q "^$toPromptName [^d]")
							then
								catfile
								# Récupération du contenu du fichier
								# toPromptFile=$(echo "$currentArchive" | egrep "^$toPromptName [^d]")

								# Récupération ligne de début du contenu
								# toPromptBegin=$(echo "$toPromptFile" | cut -d" " -f4)

								# toPromptBegin=$((toPromptBegin+bodyBegin-1))

								# Récupération longueur
								# toPromptLength=$(echo "$toPromptFile" | cut -d" " -f5)

								# Calcul ligne de fin
								# toPromptEnd=$((toPromptBegin+toPromptLength-1))

								# Suppression fichier (headder)
								# currentArchive=$(echo "$currentArchive" | sed "s/${toPromptFile}//")
								# Suppression fichier (body)
								#currentArchive=$(echo "$currentArchive" | sed "${toPromptBegin},${toPromptEnd}s/.*//")
								# echo "$toPromptName contains :"
								# echo "$currentArchive"
						else
							echo "No file found"
						fi
				fi
			
			# Chemin relatif
			else
				
				if (echo "$toPrompt" | egrep -q "/")
					# On souhaite afficher un fichier dans un dossier fils
					then
						# On récupère le chemin de l'entité à afficher
						if [ "$currentDirectory" = "/" ]
							then
								toPromptPath=$(echo "/$toPrompt" | sed -r 's/(\/[^\/]+)$//')
							else
								toDeletePath=$(echo "$currentDirectory/$toPrompt" | sed -r 's/(\/[^\/]+)$//')
						fi

						# On recupére le nom de l'entité à afficher
						toPromptName=$(echo "$toPrompt" | egrep -o "[[:alnum:]]+$")

						# On regarde si le chemin existe
						if (echo "$currentArchive" | egrep -q "^directory $root$toPromptPath$")
							
							# On regarde si le fichier est dans le contenu du dossier	
							then
								currentContent=$(echo "$currentArchive" | awk -v directory="$root$toPromptPath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
								# On regarde si l'entité existe dans le contenu de ce chemin et est un fichier
									if (echo "$currentContent" | egrep -q "^$toPromptName [^d]")
										then
											catfile
											# # On supprime le fichier
											# # Récupération du contenu du fichier
											# toDeleteFile=$(echo "$currentContent" | egrep "^$toDeleteName [^d]")

											# # Récupération ligne de début du contenu
											# toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)

											# toDeleteBegin=$((toDeleteBegin+bodyBegin-1))

											# # Récupération longueur
											# toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)

											# # Calcul ligne de fin
											# toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))

											# # Suppression fichier (header)
											# currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
											# # Suppression fichier (body)
											# currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
											# echo "$toDeleteName deleted"
											# echo  "$currentArchive"

							# On regarde si l'entité existe dans le contenu de ce chemin et est un dossier
							elif (echo "$currentContent" | egrep -q "^$toDeleteName [d]")
								then

									toPromptContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath/$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
									toPromptFile=$(echo "$currentContent" | egrep "^$toDeleteName [d]")
									echo "$toPromptName is a directory and cannot be prompt by cat"

									# # On sauvegarde IFS et on le change pour la fonction récurrente
									# oldIFS=$IFS
									# IFS=$'\n'
									# deleteDirectory $toDeleteName "$toDeletePath" "$toDeleteContent" "$toDeleteFile"
									# # Restauration de IFS
									# IFS=$oldIFS
								else
									echo "No file or directory found there"
							fi
					else
						echo "No such path found"
					fi


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
					if (echo "$currentArchive" | egrep -q "^directory $root$toDeletePath$toDeleteName ?$")
					then
						toDeleteFile=$(echo "$toDeletePathContent" | egrep "^$toDeleteName d")
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')

						# On sauvegarde IFS et on le change pour la fonction récurrente
						oldIFS=$IFS
						IFS=$'\n'
						deleteDirectory $toDeleteName "$toDeletePath" "$toDeleteContent" "$toDeleteFile"
						# Restauration de IFS
						IFS=$oldIFS

					# On vérifie que le chemin est un directory : l'entité est un dossier (cas où le dossier n'est pas à la racine)
					elif (echo "$currentArchive" | egrep -q "^directory $root$toDeletePath/$toDeleteName ?$")
					then
						toDeleteFile=$(echo "$toDeletePathContent" | egrep "^$toDeleteName d")
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath/$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						# On sauvegarde IFS et on le change pour la fonction récurrente
						oldIFS=$IFS
						IFS=$'\n'
						deleteDirectory $toDeleteName "$toDeletePath" "$toDeleteContent" "$toDeleteFile"
						# Restauration de IFS
						IFS=$oldIFS

					# On vérifie que le nom existe et que les permissions ne commencent pas par d : l'entité est un fichier
					elif (echo "$toDeletePathContent" | egrep -q "^$toDeleteName [^d]")
					then

						# Récupération du contenu du fichier
						toDeleteFile=$(echo "$currentArchive" | egrep "^$toDeleteName [^d]")

						# Récupération ligne de début du contenu
						toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)

						toDeleteBegin=$((toDeleteBegin+bodyBegin-1))

						# Récupération longueur
						toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)

						# Calcul ligne de fin
						toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))

						# Suppression fichier (headder)
						currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
						# Suppression fichier (body)
						currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
						echo "$toDeleteName deleted"
						echo "$currentArchive"
					else
						echo "No directory or file found"
					fi
				fi
			# Chemin relatif
			else
				
				if (echo "$toDelete" | egrep -q "/")
				# On souhaite supprimer dans un dossier fils
				then
					# On récupère le chemin de l'entité à supprimer
					if [ "$currentDirectory" = "/" ]
					then
						toDeletePath=$(echo "/$toDelete" | sed -r 's/(\/[^\/]+)$//')
					else
						toDeletePath=$(echo "$currentDirectory/$toDelete" | sed -r 's/(\/[^\/]+)$//')
					fi

					# On recupére le nom de l'entité à supprimer
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")

					# On regarde si le chemin existe
					if (echo "$currentArchive" | egrep -q "^directory $root$toDeletePath$")
					# On regarde si le fichier/dossier est dans le contenu du dossier	
					then
						
						currentContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						# On regarde si l'entité existe dans le contenu de ce chemin et est un fichier
						if (echo "$currentContent" | egrep -q "^$toDeleteName [^d]")
						then

							# On supprime le fichier
							# Récupération du contenu du fichier
							toDeleteFile=$(echo "$currentContent" | egrep "^$toDeleteName [^d]")

							# Récupération ligne de début du contenu
							toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)

							toDeleteBegin=$((toDeleteBegin+bodyBegin-1))

							# Récupération longueur
							toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)

							# Calcul ligne de fin
							toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))

							# Suppression fichier (header)
							currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
							# Suppression fichier (body)
							currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
							echo "$toDeleteName deleted"
							echo  "$currentArchive"

						# On regarde si l'entité existe dans le contenu de ce chemin et est un dossier
						elif (echo "$currentContent" | egrep -q "^$toDeleteName [d]")
						then

						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath/$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						toDeleteFile=$(echo "$currentContent" | egrep "^$toDeleteName [d]")

						# On sauvegarde IFS et on le change pour la fonction récurrente
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
					fi

				# On souhaite supprimer dans le dossier courant
				else
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")

					# On liste le contenu du dossier courant
					currentContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')

					toDeletePath="$currentDirectory"
					
					# On vérifie que l'entité existe et est un dossier
					if (echo "$currentContent" | egrep -q "^$toDeleteName d")
					then
							if [ $currentDirectory = "/" ]
							then							
								echo "Directory found"
								toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$toDeletePath$toDeleteName" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
								toDeleteFile=$(echo "$currentContent" | egrep "$toDeleteName d")
								# On sauvegarde IFS et on le change pour la fonction récurrente
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
								toDeleteFile=$(echo "$currentContent" | egrep "$toDeleteName d")
								# On sauvegarde IFS et on le change pour la boucle for
								oldIFS=$IFS
								IFS=$'\n'
								deleteDirectory $toDeleteName $toDeletePath "$toDeleteContent" "$toDeleteFile"
								# Restauration de IFS
								IFS=$oldIFS
							fi

					# On vérifie que le nom existe dans le dossier courant et que les permissions ne commencent pas par d : l'entité est un fichier
					elif (echo "$currentContent" | egrep -q "^$toDeleteName [^d]")
					then

						# Récupération du contenu du fichier
						toDeleteFile=$(echo "$currentArchive" | egrep "^$toDeleteName [^d]")

						# Récupération ligne de début du contenu
						toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)

						toDeleteBegin=$((toDeleteBegin+bodyBegin-1))

						# Récupération longueur
						toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)

						# Calcul ligne de fin
						toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))

						# Suppression fichier (header)
						currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
						# Suppression fichier (body)
						currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
						echo "$toDeleteName deleted"
						echo "$currentArchive"
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
	echo -n "vsh:> "
done
