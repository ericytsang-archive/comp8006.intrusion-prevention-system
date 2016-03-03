#!/bin/bash

###########################################################################################################
#ADMIN DEFINED VARIABLES

#DATABASE PATH
DB_PATH="/home/manuelg/Documents/ips/database.csv"

#ARCHIVE LOG PATH
ARCH_PATH="/home/manuelg/Documents/ips/log_copy.txt"

#SCRIPT PATH
SCRIPT_PATH="/home/manuelg/Documents/ips/ips.sh"


#END OF ADMIN DEFINED VARIABLES
###########################################################################################################

#ARG1: LOG FILE TO WATCH
#ARG2: NUMBER OF ATTEMPTS BEFORE BANNING
#ARG3: BANNING TIME

re='^[0-9]+$'

if [[ "$#" -ne 3 ]] ; then

	echo "USAGE: [log_file_path] [Attempts Number] [Banning Time (s)]" 1>&2
	exit 1

fi

if [[ ! -e "$1" || ! -r "$1" ]] ; then

	echo "Log File doesn't exist or is not readable" 1>&2
	exit 1

fi

if [[ ! "$2" =~ $re || ! "$3" =~ $re ]] ; then

	echo "Attempts and Time must be a number" 1>&2
	exit 1

fi


touch $DB_PATH
touch $ARCH_PATH

chmod 777 $DB_PATH

echo "IP ADDRESS, ATTEMPTS, LAST ATTEMPT TIME" >> $DB_PATH

echo "* * * * * $SCRIPT_PATH $1 $2 $3 $DB_PATH $ARCH_PATH" | crontab




