#!bin/bash

# Les fonctions comme extract sont appelées par le script "server"
	
# Ferme le client si l'utilisateur a oublié de mettre l'archive
if [ -z $4 ]
	then
		echo "No archive given"
		echo "Usage : vsh -extract [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
		exit 1
fi

echo ""
# On stocke le répertoire courant pour la future extraction 
dirextract=$5

# On stocke le chemin absolu vers le dossier tmp
cd tmp
dirtmp=$(pwd)

# On stocke le chemin absolu vers le dossier archives et l'archive en question
cd ../../archives
dirArchives=$(pwd)
currentArchive=$(cat $dirArchives/$4)

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
for line in $header
	do 
		# Si la ligne commence par "directory", on va créer l'arborescence qui est détaillée dans la suite de la ligne
		if [[ $(echo "$line" | egrep "^directory") ]] 
			then
				arborescence=$(echo "$line" | cut -d " " -f 2)
				# pour éviter la re-création d'un dossier plus tard dans l'archive (ce qui ferait potentiellement perdre les attributions de permission)
				if [[ ! -d  $arborescence ]] 
					then
						mkdir -p $dirextract/$arborescence
						echo "The folder tree $arborescence has been created"
						# Il faut se placer dans le niveau d'aborescence créé pour pouvoir ensuite créer les fichiers et répertoires du niveau
						cd $dirextract/$arborescence 
					else
						echo "The folder tree $arborescence already exist" 					
						# Il faut se placer dans le niveau d'aborescence créé pour pouvoir ensuite créer les fichiers et répertoires du niveau
						cd $dirextract/$arborescence 
				fi
		
		# Si la ligne contient nom_dossier/espace/d => décrit un répertoire (permissions + taille)
		elif [[ $(echo "$line" | egrep "^\w+\sd") ]]  
			then
				# On récupère le nom du dossier :
				namedir=$(echo "$line" | cut -d " " -f 1)
				
				# On récupère les permissions à affecter au dossier :
				dirperm=$(echo "$line" | cut -d " " -f 2)
				dirpermu=$(echo "$line" | cut -d " " -f 2 | sed -e "s/^d\(...\)......$/\1/" | sed -e "s/-//g")
				dirpermg=$(echo "$line" | cut -d " " -f 2 | sed -e "s/^d...\(...\)...$/\1/" | sed -e "s/-//g")
				dirpermo=$(echo "$line" | cut -d " " -f 2 | sed -e "s/^d......\(...\)$/\1/" | sed -e "s/-//g")
				
				if [[ ! -d $namedir ]]
					then
						# On crée le répertoire
						mkdir -p $namedir
						echo "The directory $namedir has been created"
						
						# On attribue les permissions du répertoire
						chmod 000 $namedir
						chmod u+$dirpermu,g+$dirpermg,o+$dirpermo $namedir
						echo "Its permissions are $dirperm"
					else
						echo "The directory $namedir already exist" 
				fi

		# Si la ligne finit par 3 nb séparés par des espace => décrit un fichier (permissions + taille + emplacement dans body)
		elif [[ $(echo "$line" | egrep "^\w+\s[^d]") ]] 
			then
				echo ""
				# On va affecter à des variables le nom et l'emplacement du contenu du fichier  :
				namef=$(echo "$line" | cut -d " " -f 1) 
					echo "Processeing file $namef"
				fdebut=$(echo "$line" | cut -d " " -f 4)
					echo "Debut lign in archive body : $fdebut"
				flength=$(echo "$line" | cut -d " " -f 5)
					echo "Number of ligns in body : $flength"
				fend=$((fdebut+flength-1))
					echo "End lign in archive body : $fend"
				
				# On récupère les permissions à affecter au fichier :
				fperm=$(echo "$line" | cut -d " " -f 2)
				fpermu=$(echo "$line" | cut -d " " -f 2 | sed -e "s/^-\(...\)......$/\1/" | sed -e "s/-//g")
				fpermg=$(echo "$line" | cut -d " " -f 2 | sed -e "s/^-...\(...\)...$/\1/" | sed -e "s/-//g")
				fpermo=$(echo "$line" | cut -d " " -f 2 | sed -e "s/^-......\(...\)$/\1/" | sed -e "s/-//g")
				
				# On sauvegarde l'emplacement où l'on est pour y envoyer le fichier qui va être créé :
				curdir=$(pwd) 
				
				if [[ ! -f $namef ]]
					then
						# Si la longueur du fichier vaut 0 on utilise "touch" car le "sed" a tendance à lui implémenter du contenu au vu à cause de la rédaction du code
						if [[ $flength -eq 0 ]]
							then
								# On crée le fichier vide :
								touch $curdir/$namef 
								echo "The file $namef has been created. It's an empty file."
								
								# On attribue les permissions du répertoire
								chmod 000 $namef 
								chmod u+$fpermu,g+$fpermg,o+$fpermo $namef
								echo "Its permissions are $fperm"
							else	
								# On crée le fichier :
								echo "$body" | sed -n "$((fdebut)),$((fend))p" > $curdir/$namef
								echo "The file $namef has been created"

								# On attribue les permissions du répertoire
								chmod 000 $namef
								chmod u+$fpermu,g+$fpermg,o+$fpermo $namef
								echo "Its permissions are $fperm"
						fi
					else
						echo "The file $namef already exist" 
				fi

		# Les lignes "@" de l'archive servent de marqueur pour revenir au début de l'arborescence
		# et garantir le fonctionnement des actions sur les lignes correspondant aux arborescences
		elif [[ "$line" =~ ^@ ]]
			then
				cd $dirextract
				echo ""
				echo "Returning to base directory of extraction"
				echo $(pwd)
				echo ""

		# Message d'erreur
		else
			echo ""
			echo "Error. There is a problem in archive format. Unable to read." 
			echo ""
		fi
	done

# Rétablissement du séparateur de champ par défaut
IFS=$old_IFS 
