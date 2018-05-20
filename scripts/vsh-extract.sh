#!bin/bash

# Les fonctions sont appelées par le script "server"
# Le dossier "script" et le dossier "archives" sont au même niveau d'arborescence
# Il faut donc régulièrement avoir recours à cd ../archives pour intéragir avec son contenu 

function vsh_extract() {
	
	cd ../archives
	read input # fichier correspondant à l'archive qui va être traitée, non nécessaire lorsque la fonction sera appelée par server
	
	awk '/^directory/ {print $2}' $input > ../scripts/tmp/tmp-extract # $input sera normalement remplacé par $4, provenant de la commande vsh -extract [serveur] [port] [archive]
	#cat ../scripts/tmp/tmp-extract # Pour vérifier que le fichier tmp-extract contient bien ce que l'on veut
	while read line
		do
	 		mkdir -p $line # crée l'arborescence de dossiers
	 	done < ../scripts/tmp/tmp-extract
	rm ../scripts/tmp/tmp-extract
	
	awk 

}

vsh_extract # indispensable actuellement pour tester la fonction (vu qu'elle n'est pas encore appelée par server)
