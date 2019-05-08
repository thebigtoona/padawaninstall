#!/bin/bash

echo $(cd "$1" && docker-compose build)
sleep 3s
echo $(cd "$1" && docker-compose up -d)
