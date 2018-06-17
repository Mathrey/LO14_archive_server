#!bin/bash

# Les fonctions sont appelées par le script "server"
# Le dossier "script" et le dossier "archives" sont au même niveau d'arborescence
# Il faut donc régulièrement avoir recours à cd ../archives pour intéragir avec son contenu 

# le nombre de lignes du résultat de "ls" sur le dossier archive donne le nombre d'archives
nb_lignes=$(ls -t ../archives/ | wc -l) 
echo ""
# le HERE sera remplacé par $2 lorsque le fichier sera appelé par server
echo "$nb_lignes archives are currently on $2" 
echo ""
echo "The following list is sorted by time modified (most recently modified first) :"
echo ""
ls -1t ../archives/
echo ""
