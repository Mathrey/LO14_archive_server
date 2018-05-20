#!bin/bash

# Les fonctions sont appelées par le script "server"
# Le dossier "script" et le dossier "archives" sont au même niveau d'arborescence
# Il faut donc régulièrement avoir recours à cd ../archives pour intéragir avec son contenu 

function vsh_extract() {
	
	cd ../archives
	#functionaldir=pwd
	read input # fichier correspondant à l'archive qui va être traitée, non nécessaire lorsque la fonction sera appelée par server
	echo ""

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
	
	hdebut=$(sed '1q' $input | cut -d : -f 1) # la variable hdebut donne la ligne où commence le header de l'archive
	bdebut=$(sed '1q' $input | cut -d : -f 2) # la variable bdebut donne la ligne où commence le body de l'archive
	hend=$(($bdebut-1)) # la variable hend donne la ligne où se termine le header de l'archive
	bend=$(sed -n '$=' $input) # la variable bend donne la ligne où se termine le body de l'archive
	echo ""

	sed -n "$((hdebut)),$((hend))p" $input > ../scripts/tmp/header
	sed -n "$((bdebut)),$((bend))p" $input > ../scripts/tmp/body

	while read -r line
		do 
			if [[ "$line" =~ ^directory ]] # si la ligne commence par "directory", on va créer l'arborescence qui est détaillée dans la suite de la ligne
				then
					if [[ ! -d  $(echo "$line" | cut -d " " -f 2) ]] # pour éviter la re-création d'un dossier plus tard dans l'archive (ce qui ferait perdre les attributions de permission)
						then
							mkdir -p $(echo "$line" | cut -d " " -f 2)
							echo "L'arborescence $(echo "$line" | cut -d " " -f 2) a été créée" 
					fi

			elif [[ "$line" =~ ^\w+\s+d ]] # si la ligne contient nom_dossier/espace/d => décrit un répertoire (permissions + taille)
				then
					mkdir -p $(echo "$line" | cut -d " " -f 1)
					# il faudra rajouter les changements de permissions

			elif [[ "$line" =~ \d+\s+\d+\s+\d+$ ]] # si la ligne finit par 3 nb séparés par des espace => décrit un fichier (permissions + taille + emplacement dans body)
				then
					name=$(echo "$line" | cut -d " " -f 1)
					echo "$name"
					fdebut=$(echo "$line" | cut -d " " -f 4)
					echo "$fdebut"
					flength=$(echo "$line" | cut -d " " -f 5)
					echo "flength"
					fend=$((fdebut+flength))
					echo "fend"
					sed -n "$((fdebut)),$((fend))p" ../scripts/tmp/body > $name
					echo "le fichier $name a été créé" 
			else
				echo "ÉCHEC" 
			fi
		done < ../scripts/tmp/header


}

vsh_extract # indispensable actuellement pour tester la fonction (vu qu'elle n'est pas encore appelée par server)
