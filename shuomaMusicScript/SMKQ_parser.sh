#!/bin/bash

KeyDelay=0.015

MINUTE=60000000000


# current status
# a: key is pressed; c: key released; b: we don't know the status.
c=b
v=b
b=b
n=b

# readArg CN1 -> pressAsHotkey C N 1
readArg(){
	args=$(echo $1|sed 's/\(.\)/\1 /g')
	eval pressAsHotkey $args
}


# pressAsHotkey C N 1 -> press down C and N, press key 1, up C and N
pressAsHotkey(){
	ct=c
	vt=c
	bt=c
	nt=c
	for (( i=1; i<$#; i++ ))
	do
		key=$(eval echo \${$i})
		eval ${key}t=a
	done
	for k_ in c v b n
	do
		curr=$(eval echo \$$k_)
		target=$(eval echo \$${k_}t)
		if [[ $curr < $target ]]
		then
			keyup $k_
		fi
		if [[ $curr > $target ]]
		then
			keydown $k_
		fi
	done
	sleep $KeyDelay
	key ${@: -1}
}

keydown(){
	echo $(date +%H:%M:%S.%N)"	keydown: "$1
	echo keydown $1 >> ${pipeName}
	eval $1=a
}

keyup(){
	echo $(date +%H:%M:%S.%N)"	keyup: "$1
	echo keyup $1 >> ${pipeName}
	eval $1=c
}

key(){
	echo $(date +%H:%M:%S.%N)"	key: "$1
	echo key $1 >> $pipeName
}



# main logic

## get input file
if [[ $# == 0 ]]
then
	echo "no shuoma key queue file specified. please choose one"
	exit 1
	return
fi

## prepare pipe

pipeName="/tmp/dstMusicPipe-"$(date +%s%N)

mkfifo ${pipeName}
tail -n +1 -f ${pipeName}|xte &




BPM=120

numberRegex='^[0-9]+([.][0-9]+)?$'

startDate=$(date +%s%N)


## read file

lineNum=1
tickCount=0
cat $1|while read l
do
	echo "read line "$lineNum": "$l
	((lineNum++))

	if [[ $l =~ BPM=* ]]
	then
	  tickCount=0
	  startDate=$(date +%s%N)
	  BPM=$(echo $l|sed 's/BPM=//')
	  echo "settig BPM to "$BPM
	  if ! [[ $BPM =~ $numberRegex ]]
    then
    	echo "BPM \""$BPM"\" is not a positive number."
    	exit 1
    	return
    fi
	else
	  	sleepTime=$(echo "scale=9;(($MINUTE/$BPM*$tickCount) - $(date +%s%N) + $startDate)/1000000000"|bc)
    	if (( $(echo "$sleepTime > 0"|bc -l) ))
    	then
    		sleep $sleepTime
    	fi
	  ((tickCount++))
	  for j in $l
    do
    	readArg $j
    done
	fi
done

echo "">$pipeName
rm $pipeName
