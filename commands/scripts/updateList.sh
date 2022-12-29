#!/bin/bash
dir=$(dirname $0)
cd "$dir"
echo "return {" > moduleList.lua
for i in `ls --ignore={"example.lua","moduleList.lua","template.lua","log.lua"} | grep '^.*\.lua$'`
do
  echo "add module: " $i "to moduleList.lua"
  filename=$(echo $i|sed 's/\.lua$//')
  printf "\t"'"'$filename'",'"\n" >> "moduleList.lua"
done
printf "}" >> "moduleList.lua"

if [[ -f "update.hook" ]]
then
  echo "execute update.hook ..."
  "./update.hook"
fi