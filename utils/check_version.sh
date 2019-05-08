#!/bin/bash

currentver="$($1 --version)"
requiredver="$2"
 if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]
 then 
        echo "$currentver is greater than or equal to $requiredver"
 else
        echo "Less than $requiredver"
        echo "updgrade your docker-compose to at least $requiredver"
        exit 1
fi
