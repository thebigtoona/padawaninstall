#!/bin/bash

checkOSVersion () {
  unameOut="$(uname -s)"
  case "${unameOut}" in
      Linux*)     machine=Linux;;
      Darwin*)    machine=Mac;;
      CYGWIN*)    machine=Cygwin;;
      MINGW*)     machine=MinGw;;
      *)          machine="UNKNOWN:${unameOut}"
  esac

  OSVersion=${machine}
  echo -e "Setting OS version as ${OSVersion}...\n"

  return 
}

checkSystemDependency () {
  local dependency=$1
  if [[ -n $($dependency --version) ]]
  then
    echo -e "`$dependency --version`"
  else 
    echo "Cannot locate $dependency version.  $dependency is required, exiting..."
    exit 1
  fi

  return 
}

checkVersionCompatibiity () {
  local currentver="$($1 --version)"
  local requiredver="$2"
  if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]
  then 
          echo "$currentver is greater than or equal to $requiredver"
  else
          echo "Less than $requiredver"
          echo "updgrade your docker-compose to at least $requiredver"
          exit 1
  fi

  return 
}

dockerBuildContainer () {
  local projectLoc=$1
  cd $projectLoc && docker-compose build
  return 
}

dockerRaiseContainer () {
  local projectLoc=$1
  cd $projectLoc && docker-compose up -d
  return 
}

cloneInRepo () {
  local dir=$1
  local repoURL=$2
  $(cd $dir && git clone $repoURL)
  return 
}

checkoutBranch () {
  local dir=$1
  local branch=$2
  cd $dir && git checkout $branch
  return 
}

npmInstall () {
  local dir=$1
  npm i --prefix $dir
  return 
}

meteorReset () {
  local dir=$1
  cd $dir && meteor reset
}

# install dir 
installDirectory=$1

# system dependencies 
dependencies=(
  "docker" 
  "git"
  "meteor"
  "node"
  "npm"
)

# dir loc of install script 
scriptDirectory=$(dirname $0)

# running os version check 
checkOSVersion

# TODO: create a verbose mode 
if [[ "$2" == "verbose" ]]
then 
  echo -e "Running Verbose \n"
fi 

# check for install directory specification 
if [ -z "$1" ]
then 
  echo "You did not set an installtion directory"
  read -p "Please set a location or use the default provided: " -ei "$HOME/developerlevel" installDirectory
  echo "install directory: $installDirectory"
fi 

# if there is no directory, make one 
if [ -d $installDirectory ]
then 
  echo "Your installation directory is set to: $installDirectory"
else 
  echo "creating directory: $installDirectory"
  $(mkdir $installDirectory)
  echo "Your installation directory is set to: $installDirectory"
fi 


# run dependency checks 
echo -e "2. Running checks for dependencies...\n"

# checks for each dependency by checking its version 
for DEP in "${dependencies[@]}"; do
  echo -e "checking for $DEP..."
  checkSystemDependency $DEP
done

echo -e "checking docker-compose version for compatibility..."
checkVersionCompatibiity "docker-compose" "1.18.0"

# TODO: create working checks for mac
if [ $OSVersion == "Linux" ]
then 
  if [[ $(systemctl is-active docker) == "inactive" ]]
  then 
    echo "starting docker... "
    $(sudo systemctl start docker)
    echo -e "Docker Status: $(systemctl is-active docker)\n"
  else 
    echo -e "Docker Status: $(systemctl is-active docker)\n"
  fi 
elif [ $OSVersion == "Mac" ]
then 
  if (! docker stats --no-stream ); then
    # On Mac OS this would be the terminal command to launch Docker
    open /Applications/Docker.app
    #Wait until Docker daemon is running and has completed initialisation
    while (! docker stats --no-stream ); do
      # Docker takes a few seconds to initialize
      echo "Waiting for Docker to launch..."
      sleep 1
    done
  fi
else 
  echo "OS not supported for this script, exiting..."
  exit 1
fi


# check if aarc directory exists
if [ -d "$installDirectory/aarc" ]
then 

  echo -e "aarc already exists...\n"

  checkoutBranch "$installDirectory/aarc/" "feature/DevDocker"
  AARC_DIR="$installDirectory/aarc" 

else

  echo "aarc is not in the specified installation directory.  cloning into $installDirectory..."

  cloneInRepo $installDirectory "https://github.com/paladinarcher/aarc.git"  
  checkoutBranch "$installDirectory/aarc/" "feature/DevDocker"

  echo "adding variable.env file..."
  $(cp "$(pwd)/variables.env" "$installDirectory/aarc/api/")
  
  AARC_DIR="$installDirectory/aarc" 

fi 

# check if tsq directory exists 
if [ -d "$installDirectory/TSQ-Microservice" ]
then 
  echo -e "tsq exists, skipping...\n"
  TSQ_DIR="$installDirectory/TSQ-Microservice/"
else
  echo "tsq is not in the specified work directory.  cloning into $installDirectory..."
  cloneInRepo $installDirectory "https://github.com/paladinarcher/TSQ-Microservice.git"
  TSQ_DIR="$installDirectory/TSQ-Microservice/"
fi 

# check if the padawan directory exists 
if [ -d "$installDirectory/padawan" ]
then 
  echo -e "padawan already exists...\n"
  
  checkoutBranch "$installDirectory/padawan/" "staging" 
  
  echo -e "installing padawan npm dependencies...\n"

  meteor npm install --prefix "$installDirectory/padawan/"
  
  PADAWAN_DIR="$installDirectory/padawan"
  
  meteorReset $PADAWAN_DIR
  
  echo ""

else
  echo "padawan is not in the specified work directory.  cloning into $installDirectory..."
  
  cloneInRepo $installDirectory "https://github.com/paladinarcher/padawan.git"
  checkoutBranch "$installDirectory/padawan/" "staging" 
  
  echo -e "installing padawan npm dependencies...\n"

  meteor npm install --prefix "$installDirectory/padawan/"

  PADAWAN_DIR="$installDirectory/padawan"
  
  meteorReset $PADAWAN_DIR
  
  echo ""
fi 

echo ""

NPM_INSTALLS=( "$installDirectory/aarc/frontend" "$installDirectory/aarc/api"  "$installDirectory/TSQ-Microservice")


echo -e "installing dependencies via npm...\n"
for install_dir in "${NPM_INSTALLS[@]}"; do
  npmInstall $install_dir
  echo ""
done 

echo -e "starting TSQ...\n"
dockerRaiseContainer $TSQ_DIR

echo -e "\nbuilding aarc...\n"
dockerBuildContainer "$AARC_DIR/docker/aarc_dev"
echo -e "raising aarc...\n"
dockerRaiseContainer "$AARC_DIR/docker/aarc_dev"

echo -e "\nbuilding padawan app container...\n"
dockerBuildContainer "$PADAWAN_DIR/docker/dev/"
echo -e "\nraising padawan app container...\n"
dockerRaiseContainer "$PADAWAN_DIR/docker/dev/"

echo -e "\ninstalling meteor and starting padawan in the app container... \n\n"

printf "\nstarting up application container, this may take awhile..."
while [ $(docker logs dev_app_1 2>&1 | grep "App running at: http://localhost" -c -i) -lt 1 ];
do 
  printf "."
  sleep 1s
done 

echo -e "\n"
echo "application container started! navigate to http://localhost:3000"
echo "if you want to see what's going on in a container look at the logs with docker logs <container name>"
echo "you can follow a container with docker logs -f <container name>"
exit 0
