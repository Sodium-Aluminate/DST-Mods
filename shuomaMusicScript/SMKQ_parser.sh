#!/bin/bash

KeyDelay=0.015

MINUTE=60000000000


# current status
c=0
v=0
b=0
n=0

# readArg CN1 -> pressAsHotkey C N 1
readArg(){
	args=$(echo $1|sed 's/\(.\)/\1 /g')
	eval pressAsHotkey $args
}


# pressAsHotkey C N 1 -> press down C and N, press key 1, up C and N
pressAsHotkey(){
	ct=0
	vt=0
	bt=0
	nt=0
	for (( i=1; i<$#; i++ ))
	do
		key=$(eval echo \${$i})
		eval ${key}t=1
	done
	for k_ in c v b n
	do
		curr=$(eval echo \$$k_)
		target=$(eval echo \$${k_}t)
		if [[ $curr > $target ]]
		then
			keyup $k_
		fi
		if [[ $curr < $target ]]
		then
			keydown $k_
		fi
	done
	sleep $KeyDelay
	key ${@: -1}
}

keydown(){
	echo $(date +%H:%M:%S.%N)"	keydown: "$1
	echo keydown $1 >> ${pipeName}_$1 &
	eval $1=1
}

keyup(){
	echo $(date +%H:%M:%S.%N)"	keyup: "$1
	echo keyup $1 >> ${pipeName}_$1 &
	eval $1=0
}

key(){
	echo $(date +%H:%M:%S.%N)"	key: "$1
	echo key $1 >> $pipeName &
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
mkfifo ${pipeName}_c
mkfifo ${pipeName}_v
mkfifo ${pipeName}_b
mkfifo ${pipeName}_n
mkfifo ${pipeName}
tail -n +1 -f ${pipeName}_c|xte &
tail -n +1 -f ${pipeName}_v|xte &
tail -n +1 -f ${pipeName}_b|xte &
tail -n +1 -f ${pipeName}_n|xte &
tail -n +1 -f ${pipeName}|xte &


## BPM 

BPM=120
BPMHeadlineTag=false
headline=$(head -n1 $1)

if [[ $headline == BPM=* ]]
then 
	BPM=$(echo $headline|sed 's/BPM=//')
	BPMHeadlineTag=true
fi


numberRegex='^[0-9]+([.][0-9]+)?$'
if ! [[ $BPM =~ $numberRegex ]]
then
	echo "BPM \""$BPM"\" is not a positive number."
	exit 1
	return
fi

startDate=$(date +%s%N)


## read file
readFileCommand=cat
if [[ $BPMHeadlineTag == true ]]
then 
	readFileCommand="sed 1d"
fi

lineNum=1
$readFileCommand $1|while read l
do
	echo "readline :"$lineNum"("$l")"
	# sync time
	sleepTime=$(echo "scale=9;(($MINUTE/$BPM*$lineNum) - $(date +%s%N) + $startDate)/1000000000"|bc)
	if [[ $sleepTime > 0 ]]
	then
		sleep $sleepTime
	fi
	
	
	for j in $l
	do
		readArg $j
	done
	((lineNum++))																															
done

echo "">$pipeName
rm $pipeName
