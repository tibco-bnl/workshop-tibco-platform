#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Usage: $0 <find> <replace> <file>"
  exit 1
fi

find="$1"
replace="$2"
file="$3"

# Construct the search pattern to match the specific format
search_pattern="$find:-.*}"

# Construct the replace pattern
replace_pattern="$find:-$replace}"

sed -i "s/$search_pattern/$replace_pattern/g" "$file"