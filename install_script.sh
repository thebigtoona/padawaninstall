#!/bin/bash

# need these params: aarc dir, tsq dir, padawan dir 
# $1 = developerlevel directory loc

WORKDIR=$1
PGREP="/usr/bin/pgrep"

echo "1. Your work directory is: $WORKDIR"
echo "2. Running checks for dependencies... "

echo ""

# run verbose mode 
if [[ "$2" == "verbose" ]]
then 
  echo "Running Verbose"
fi 

echo ""

# check for docker install 
echo "checking for docker..."
if [[ -n $(docker --version) ]]
then
  echo "DOCKER: `docker --version`"
else 
  echo "Cannot locate docker version.  Docker is required, exiting..."
  exit 1
fi

echo ""

# check for git install
echo "checking for git..."
if [[ -n $(git --version) ]]
then
  echo "GIT: `git --version`"
else 
  echo "Cannot locate git version.  Git is required, exiting..."
  exit 1
fi

echo ""

# check for node install
echo "checking for node..."
if [[ -n $(node --version) ]]
then
  echo "NODE: `node --version`"
else 
  echo "Cannot locate Node version.  Node is required, exiting..."
  exit 1
fi

echo ""

# check for meteor install
echo "checking for meteor..."
if [[ -n $(meteor --version) ]]
then
  echo "METEOR: `meteor --version`"
else 
  echo "Cannot locate Meteor version.  Meteor is required, exiting..."
  exit 1
fi 

echo ""

# check if docker is started 
# true: proceed / false: attempt to start docker and exit script if fail  
if [[ $(systemctl is-active docker) == "inactive" ]]
then 
  echo "starting docker... "
  echo $(sudo systemctl start docker)
  echo "Docker Status: $(systemctl is-active docker)"
else 
  echo "Docker Status: $(systemctl is-active docker)"
fi 

# check if aarc directory exists
if [ -d "$WORKDIR/aarc" ]
then 
  echo "starting up aarc"
  echo -e $(cd "$WORKDIR/aarc/docker/aarc_dev/" && docker-compose build)
  echo -e $(cd "$WORKDIR/aarc/docker/aarc_dev/" && docker-compose up -d)
else
  echo "aarc is not in the specified work directory.  cloning into $WORKDIR..."
  
  echo $(cd "$WORKDIR" && git clone https://github.com/paladinarcher/aarc.git)
  echo $(cd "$WORKDIR/aarc/" && git checkout feature/DevDocker)
  
  echo "installing frontend dependencies via npm... " 
  echo $(npm install --prefix $WORKDIR/aarc/frontend/)

  echo "installing backend dependencies via npm... " 
  echo $(npm install --prefix $WORKDIR/aarc/api/)
  
  echo "adding variable.env file..."

  echo -e $(cp "$(pwd)/variables.env" "$WORKDIR/aarc/api/")

  echo "starting up aarc"
  echo -e $(cd "$WORKDIR/aarc/docker/aarc_dev/" && docker-compose build)
  echo -e $(cd "$WORKDIR/aarc/docker/aarc_dev/" && docker-compose up -d)
fi 

# check if tsq directory exists 
if [ -d "$WORKDIR/TSQ-Microservice" ]
then 
  echo "starting up tsq"
  echo -e $(cd "$WORKDIR/TSQ-Microservice" && docker-compose up -d)
else
  echo "tsq is not in the specified work directory.  cloning into $WORKDIR..."
  
  echo $(cd "$WORKDIR" && git clone https://github.com/paladinarcher/TSQ-Microservice.git)
  
  echo "installing dependencies via npm... " 
  echo $(npm install -C $WORKDIR/TSQ-Microservice)

  echo "starting up tsq"
  echo -e $(cd "$WORKDIR/TSQ-Microservice/" && docker-compose up -d)
fi 

# check if the padawan directory exists 
if [ -d "$WORKDIR/padawan" ]
then 
  echo "starting up padawan"
  echo -e $(cd "$WORKDIR/padawan/docker/dev/" && docker-compose build)
  echo -e $(cd "$WORKDIR/padawan/docker/dev/" && docker-compose up -d)
else
  echo "padawan is not in the specified work directory.  cloning into $WORKDIR..."
  
  echo $(cd "$WORKDIR" && git clone https://github.com/paladinarcher/padawan.git)
  echo $(cd "$WORKDIR/padawan/" && git checkout staging)
  
  echo "installing dependencies via npm... " 
  echo $(meteor npm install --prefix $WORKDIR/padawan/)

  echo "starting up padawan"
  echo -e $(cd "$WORKDIR/padawan/docker/dev/" && docker-compose build)
  echo -e $(cd "$WORKDIR/padawan/docker/dev/" && docker-compose up -d)
fi 