#!/bin/bash

echo $(cd "$1" && docker-compose build)
echo $(cd "$1" && docker-compose up -d)
