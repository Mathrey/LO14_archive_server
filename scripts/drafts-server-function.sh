#!/bin/bash

# Ce script va répondre à l'appel du serveur et renvoyer la fonction adéquate
# Le script doit être invoqué avec list | extract | browse selon leur syntaxe

function vsh_list() {

	case $input in

		list && \w+ && \d+ ) echo "Bonne syntaxe"
			;;

		*) echo "usage : list [NOM_SERVEUR] [PORT]"
			;;

	esac 

}

read input

case $input in 

	list ) vsh_list
		;;

	extract ) vsh_extract
		;;
	
	browse ) vsh_browse
		;;
	* ) echo "Sorry, only use commands \"list\" || \"extract\" || \"browse\""
esac



function vsh_extract() {

}

function vsh_browse() {
	
}
