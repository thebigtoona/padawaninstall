#!/bin/bash

# $1 = directory to install everything to 

WORKDIR=$1
DEPENDENCIES=(
  "docker" 
  "git"
  "meteor"
  "node"
  "npm"
)
SCRIPTDIR=$(dirname $0)

# TODO: create a function or script out of this 
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo -e "OS INFO:  Running on ${machine}\n"

OSVER=${machine}

# TODO: create a util script for this too 
if [ -d $WORKDIR ]
then 
  echo "1. Your work directory is: $WORKDIR"
else 
  echo "1. creating directory: $WORKDIR"
  $(mkdir $WORKDIR)
  echo "1. Your work directory is: $WORKDIR"
fi 

echo -e "2. Running checks for dependencies...\n"

# TODO: create a verbose mode 
if [[ "$2" == "verbose" ]]
then 
  echo -e "Running Verbose \n"
fi 

# checks for each dependency by checking its version 
for DEP in "${DEPENDENCIES[@]}"; do
  echo -e "checking for $DEP..."
  echo -e "$(bash $SCRIPTDIR/utils/check_dep.sh $DEP)\n"
done

echo -e "checking docker-compose version for compatibility..."
echo -e "$(bash $SCRIPTDIR/utils/check_version.sh docker-compose 1.18.0)\n"

# TODO: create working checks for mac 
if [[ $(systemctl is-active docker) == "inactive" ]]
then 
  echo "starting docker... "
  echo $(sudo systemctl start docker)
  echo -e "Docker Status: $(systemctl is-active docker)\n"
else 
  echo -e "Docker Status: $(systemctl is-active docker)\n"
fi 


# check if aarc directory exists
if [ -d "$WORKDIR/aarc" ]
then 
  echo -e "aarc exists, skipping...\n"
  AARC_DIR="$WORKDIR/aarc" 
else
  echo "aarc is not in the specified work directory.  cloning into $WORKDIR..."  
  echo $(cd "$WORKDIR" && git clone https://github.com/paladinarcher/aarc.git)
  echo $(cd "$WORKDIR/aarc/" && git checkout feature/DevDocker)
  echo "adding variable.env file..."
  echo -e $(cp "$(pwd)/variables.env" "$WORKDIR/aarc/api/")
  AARC_DIR="$WORKDIR/aarc" 
fi 

# check if tsq directory exists 
if [ -d "$WORKDIR/TSQ-Microservice" ]
then 
  echo -e "tsq exists, skipping...\n"
  TSQ_DIR="$WORKDIR/TSQ-Microservice/"
else
  echo "tsq is not in the specified work directory.  cloning into $WORKDIR..."
  echo $(cd "$WORKDIR" && git clone https://github.com/paladinarcher/TSQ-Microservice.git)
  TSQ_DIR="$WORKDIR/TSQ-Microservice/"
fi 

# check if the padawan directory exists 
if [ -d "$WORKDIR/padawan" ]
then 
  echo -e "padawan already exists, skipping...\n"
  echo -e "installing padawan npm dependencies...\n"
  echo $(meteor npm install --prefix $WORKDIR/padawan/)
  PADAWAN_DIR="$WORKDIR/padawan"
  echo ""
else
  echo "padawan is not in the specified work directory.  cloning into $WORKDIR..."
  echo $(cd "$WORKDIR" && git clone https://github.com/paladinarcher/padawan.git)
  echo $(cd "$WORKDIR/padawan/" && git checkout staging)
  echo -e "installing padawan npm dependencies...\n"
  echo $(meteor npm install --prefix $WORKDIR/padawan/)
  PADAWAN_DIR="$WORKDIR/padawan"
  echo ""
fi 

echo ""

NPM_INSTALLS=( "$WORKDIR/aarc/frontend" "$WORKDIR/aarc/api"  "$WORKDIR/TSQ-Microservice")

echo -e "installing dependencies via npm...\n"

for install_dir in "${NPM_INSTALLS[@]}"; do
  echo $install_dir
  echo $(bash $SCRIPTDIR/utils/npm_installs.sh $install_dir)
  echo ""
done 

echo -e "starting TSQ...\n"
echo $(bash $SCRIPTDIR/utils/dc_up.sh $TSQ_DIR)

echo -e "starting aarc..."
echo $(bash $SCRIPTDIR/utils/dc_build_up.sh "$AARC_DIR/docker/aarc_dev/")
echo -e "starting padawan..."
echo $(bash $SCRIPTDIR/utils/dc_build_up.sh "$PADAWAN_DIR/docker/dev/")

echo -e "installing meteor and starting padawan.... \n\n"

printf "starting up application container, this may take awhile..."
while [ $(docker logs dev_app_1 2>&1 | grep "App running at: http://localhost" -c -i) -lt 1 ];
do 
  printf "."
  sleep 5s
done 

echo -e "\n"
echo "application container started! navigate to http://localhost:3000"

# echo $(cd "$PADAWAN_DIR/docker/dev/" && docker-compose build)
# echo $(cd "$PADAWAN_DIR/docker/dev/" && docker-compose up)
