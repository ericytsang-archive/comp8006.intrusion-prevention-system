#!/bin/bash

#ARG1: LOG FILE TO WATCH
#ARG2: NUMBER OF ATTEMPTS BEFORE BANNING
#ARG3: BANNING TIME
#ARG4: PATH TO CSV FILE ("DATABASE")
#ARG5: PATH TO ARCHIVE FILE ("LOG COPY")

IPT="iptables"
LOG_PATH="$1"
MAX_ATTEMPTS="$2"
BAN_TIME="$3"
DB_PATH="$4"
ARCH_PATH="$5"

TEMP_PATH=${LOG_PATH}_copy

cat $LOG_PATH > $TEMP_PATH
> $LOG_PATH
cat $TEMP_PATH >> $ARCH_PATH

#ADD ATTEMPTS, UPDATE TIME AND BAN IF NECESSARY
grep "Failed password" $TEMP_PATH | while read line ; do 

	IP_ADDRESS=$(echo $line | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

	newtime=$(date +%s)

	echo "GREP RUNS"

	if grep -q "$IP_ADDRESS" $DB_PATH
	then

		echo "GREP FOUND IP"	

		while IFS=',' read -r ipaddr attempts eptime

		do

			if [ "$ipaddr" == "$IP_ADDRESS" ] ; then

				newcount=$(($attempts + 1))

				

				if [ $newcount -ge $MAX_ATTEMPTS ] ; then

					grep -v $IP_ADDRESS $DB_PATH > $DB_PATH
					echo "$IP_ADDRESS , $newcount , $newtime" >> $DB_PATH
					$IPT -I INPUT 1 -s "$ipaddr" -j DROP

				else

					grep -v $IP_ADDRESS $DB_PATH > $DB_PATH
					echo "$IP_ADDRESS , $newcount , $newtime" >> $DB_PATH
					echo "here"

				fi

				break

			fi

		done < $DB_PATH

	else

		echo "$IP_ADDRESS , 1 , $newtime" >> $DB_PATH
		echo "GREP NOT FOUND IP"

	fi

		
done

#CLEAR FROM DB
grep "Accepted password" $TEMP_PATH | while read -r line ; do 

	IP_ADDRESS=$(awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

	if grep -q "$IP_ADDRESS" $DB_PATH
	then	

		grep -v $IP_ADDRESS $DB_PATH > $DB_PATH

	fi
		
done

#UNBAN AND CLEAR FROM DB
sed 1d $DB_PATH | while IFS=',' read -r ipaddr attempts eptime
		do
			checktime=$(($eptime + $BAN_TIME))
			currentime=$(date +%s)

			if [ $currentime -ge $checktime ] ; then

				grep -v $IP_ADDRESS $DB_PATH > $DB_PATH
				$IPT -I INPUT 1 -s "$ipaddr" -j ACCEPT

			fi

		done
