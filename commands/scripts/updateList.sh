#!/bin/bash
dir=$(dirname $0)
cd "$dir"
echo "return {" > moduleList.lua
for i in `ls --ignore={"example.lua","moduleList.lua","template.lua"} | grep '^.*\.lua$'`
do
  echo "add module: " $i "to moduleList.lua"
  filename=$(echo $i|sed 's/\.lua$//')
  printf "\t"'"'$filename'",'"\n" >> "$dir/moduleList.lua"
done
printf "}" >> "$dir/moduleList.lua"

if [[ -f "$dir/update.hook" ]]
then
  echo "execute update.hook ..."
  "$dir/update.hook"
fi