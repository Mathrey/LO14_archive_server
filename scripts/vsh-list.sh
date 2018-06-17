#!bin/bash

# Les fonctions comme list sont appelées par le script "server"

# Le nombre de lignes du résultat de "ls" sur le dossier archive donne le nombre d'archives
nb_lignes=$(ls -t ../archives/ | wc -l) 
echo ""

# Le $2 correspond au [SERVER_NAME] entré par le client
echo "$nb_lignes archives are currently on $2" 
echo ""
echo "The following list is sorted by time modified (most recently modified first) :"
echo ""
ls -1t ../archives/
echo ""
