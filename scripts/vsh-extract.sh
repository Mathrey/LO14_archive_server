#!bin/bash

# Les fonctions sont appelées par le script "server"
# Le dossier "script" et le dossier "archives" sont au même niveau d'arborescence
# Il faut donc régulièrement avoir recours à cd ../archives pour intéragir avec son contenu 
	
# Ferme le client si l'utilisateur a oublié de mettre l'archive
if [ -z $4 ]
	then
		echo "No archive given"
		echo "Usage : vsh -extract [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
		exit 1
fi

# On stocke le chemin absolu vers le dossier tmp
cd tmp
dirtmp=$(pwd)

# OBSOLETE : On stocke le chemin absolu vers le dossier archives
# cd ../../archives
# dirarchive=$(pwd)

# OSBSOLETE On se place dans le dossier des scripts
# cd ../scripts

# read input # fichier correspondant à l'archive qui va être traitée, non nécessaire lorsque la fonction sera appelée par server

echo ""
asroot=$(pwd) # À changer par le répertoire du client ?

# la variable hdebut donne la ligne où commence le header de l'archive
hdebut=$(sed '1q' $input | cut -d : -f 1) 
# la variable bdebut donne la ligne où commence le body de l'archive
bdebut=$(sed '1q' $input | cut -d : -f 2) 
# la variable hend donne la ligne où se termine le header de l'archive
hend=$(($bdebut-1)) 
# la variable bend donne la ligne où se termine le body de l'archive
bend=$(sed -n '$=' $input) 
echo ""

sed -n "$((hdebut)),$((hend))p" $input > $dirtmp/header
sed -n "$((bdebut)),$((bend))p" $input > $dirtmp/body

while read -r line
	do 
		# si la ligne commence par "directory", on va créer l'arborescence qui est détaillée dans la suite de la ligne
		if [[ $(echo "$line" | egrep "^directory") ]] 
			then
				arborescence=$(echo "$line" | cut -d " " -f 2)
				# pour éviter la re-création d'un dossier plus tard dans l'archive (ce qui ferait perdre les attributions de permission)
				if [[ ! -d  $arborescence ]] 
					then
						mkdir -p $arborescence
						echo "The folder tree $arborescence has been created"
						# Il faut se placer dans le niveau d'aborescence créé pour pouvoir ensuite créer les fichiers et répertoires du niveau
						cd $arborescence 
					else
						echo "The folder tree $arborescence already exist" 					
						# Il faut se placer dans le niveau d'aborescence créé pour pouvoir ensuite créer les fichiers et répertoires du niveau
						cd $arborescence 
				fi

		# elif [[ "$line" =~ ^\w+\sd ]] # Cette version ne marche pas à cause de la gestion des regex par défaut de bash
		
		# si la ligne contient nom_dossier/espace/d => décrit un répertoire (permissions + taille)
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

		# si la ligne finit par 3 nb séparés par des espace => décrit un fichier (permissions + taille + emplacement dans body)
		elif [[ $(echo "$line" | egrep "\d+\s\d+\s\d+$") ]] 
			then
				echo ""
				
				# On va affecter à des variables le nom et l'emplacement du contenu du fichier  :
				namef=$(echo "$line" | cut -d " " -f 1) 
					echo "Processeing file $namef"
				fdebut=$(echo "$line" | cut -d " " -f 4)
					echo "Debut lign in tmp/body : $fdebut"
				flength=$(echo "$line" | cut -d " " -f 5)
					echo "Number of ligns in tmp/body : $flength"
				fend=$((fdebut+flength-1))
					echo "End lign in tmp/body : $fend"
				
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
								echo "It's permissions are $fperm"
							else	
								# On crée le fichier :
								sed -n "$((fdebut)),$((fend))p" $dirtmp/body > $curdir/$namef
								echo "The file $namef has been created"

								# On attribue les permissions du répertoire
								chmod 000 $namef
								chmod u+$fpermu,g+$fpermg,o+$fpermo $namef
								echo "It's permissions are $fperm"
						fi
					else
						echo "The file $namef already exist" 
				fi

		elif [[ "$line" =~ ^@ ]]
			then
				cd $asroot
				echo ""
				echo "Returning to base directory"
				echo $(pwd)
				echo ""

		else
			echo "ÉCHEC" 
		fi
	done < $dirtmp/header

cd $dirtmp
# rm header à mettre en place lors du rendu final
# rm body à mettre en place lors du rendu final
cd $currentDirectory

############################################################ 

# tentative première, créée l'abrorescence des dossiers mais c'est tout

	# awk '/^directory/ {print $2}' $input > ../scripts/tmp/tmp-extract # $input sera normalement remplacé par $4, provenant de la commande vsh -extract [serveur] [port] [archive]
	# #cat ../scripts/tmp/tmp-extract # Pour vérifier que le fichier tmp-extract contient bien ce que l'on veut
	# while read line
	# 	do
	#  		mkdir -p $line # crée l'arborescence de dossiers
	#  	done < ../scripts/tmp/tmp-extract
	# rm ../scripts/tmp/tmp-extract

############################################################