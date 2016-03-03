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
#secure log
grep -E 'Failed password|Connection closed|FAILED LOGIN' $TEMP_PATH | while read line ; do 

	IP_ADDRESS=$(echo $line | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

	if [ -z "$IP_ADDRESS" ] ; then
	 	continue
	fi

	newtime=$(date +%s)

	if grep -q "$IP_ADDRESS" $DB_PATH
	then	

		while IFS=',' read -r ipaddr attempts eptime

		do

			if [ "$ipaddr" == "$IP_ADDRESS" ] ; then

				newcount=$(($attempts + 1))

				if [ $newcount -ge $MAX_ATTEMPTS ] ; then

					sed -i "/\b\(${IP_ADDRESS}\)\b/d" $DB_PATH
					echo "${IP_ADDRESS},${newcount},${newtime}" >> $DB_PATH
					$IPT -I INPUT 1 -s "$IP_ADDRESS" -j DROP

				else

					sed -i "/\b\(${IP_ADDRESS}\)\b/d" $DB_PATH
					echo "${IP_ADDRESS},${newcount},${newtime}" >> $DB_PATH

				fi

				break

			fi

		done < $DB_PATH

	else

		echo "${IP_ADDRESS},1,${newtime}" >> $DB_PATH

	fi

		
done

#ADD ATTEMPTS, UPDATE TIME AND BAN IF NECESSARY
#message log
grep -E 'op=password|op=login' $TEMP_PATH | grep 'res=failed' | while read line ; do 

	IP_ADDRESS=$(echo $line | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

	if [ -z "$IP_ADDRESS" ] ; then
	 	continue
	fi

	newtime=$(date +%s)

	if grep -q "$IP_ADDRESS" $DB_PATH
	then	

		while IFS=',' read -r ipaddr attempts eptime

		do

			if [ "$ipaddr" == "$IP_ADDRESS" ] ; then

				newcount=$(($attempts + 1))

				if [ $newcount -ge $MAX_ATTEMPTS ] ; then

					sed -i "/\b\(${IP_ADDRESS}\)\b/d" $DB_PATH
					echo "${IP_ADDRESS},${newcount},${newtime}" >> $DB_PATH
					$IPT -I INPUT 1 -s "$IP_ADDRESS" -j DROP

				else

					sed -i "/\b\(${IP_ADDRESS}\)\b/d" $DB_PATH
					echo "${IP_ADDRESS},${newcount},${newtime}" >> $DB_PATH

				fi

				break

			fi

		done < $DB_PATH

	else

		echo "${IP_ADDRESS},1,${newtime}" >> $DB_PATH

	fi

		
done

#CLEAR FROM DB 
#secure log
grep -E 'Accepted password|LOGIN ON' $TEMP_PATH | while read -r line ; do 

	IP_ADDRESS=$(echo $line | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

	if grep -q "$IP_ADDRESS" $DB_PATH
	then	

		sed -i "/\b\(${IP_ADDRESS}\)\b/d" $DB_PATH

	fi
		
done

#CLEAR FROM DB 
#message log
grep 'op=login' $TEMP_PATH | grep 'res=success' | while read -r line ; do 

	IP_ADDRESS=$(echo $line | awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}')

	if grep -q "$IP_ADDRESS" $DB_PATH
	then	

		sed -i "/\b\(${IP_ADDRESS}\)\b/d" $DB_PATH

	fi
		
done

#UNBAN AND CLEAR FROM DB
sed 1d $DB_PATH | while IFS=',' read -r ipaddr attempts eptime
		do
			checktime=$(($eptime + $BAN_TIME))
			currentime=$(date +%s)

			if [ $currentime -ge $checktime ] ; then

				sed -i "/\b\(${ipaddr}\)\b/d" $DB_PATH
				$IPT -I INPUT 1 -s "$ipaddr" -j ACCEPT

			fi

		done
