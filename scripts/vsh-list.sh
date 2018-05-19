#!bin/bash

function vsh_list() {

	case $input in

		list && \w+ && \d+ ) echo "Bonne syntaxe"
			;;

		*) echo "usage : list [NOM_SERVEUR] [PORT]"
			;;

	esac 

}