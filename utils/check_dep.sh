#!/bin/bash

DEP="$1"

if [[ -n $($DEP --version) ]]
then
  echo -e "INFO:  `$DEP --version`"
else 
  echo "Cannot locate $DEP version.  $DEP is required, exiting..."
  exit 1
fi