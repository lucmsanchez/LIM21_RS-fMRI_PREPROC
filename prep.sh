#!bin/bash

source config
if [ -f "$pathpi"/subs.txt ]
	then echo "A lista já existe"
	else
		source config
		cd "$pathpi"
		ls | grep -P '(?<=RS_)\w*(?<=.)' -o > subs.txt
fi

