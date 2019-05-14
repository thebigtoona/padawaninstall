# Install Helper for Padawan 

![GitHub release](https://img.shields.io/github/release-pre/thebigtoona/padawaninstall.svg)
![GitHub issues](https://img.shields.io/github/issues/thebigtoona/padawaninstall.svg)
![Supported Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20OSX-9cf.svg)

## Things to Note

* This script is cross compatible for Mac and Linux, however due to current issues with 
the aarc branch the script uses, the mac version will not work out of the box. See 
[Known Issues](#known-issues)  
* The script is still very basic and needs a lot of adjustment.  It won't catch every 
exception or error at this time.  Please create an issue for any error you run into  
* The script runs your docker containers as detached, but you can view thier logs and see them 
running in the list of containers by using docker commands. [Docker Help](#docker-help)


## Installation

1. clone the repo to wherever you keep your scripts.  The install script is located in 
the root of the repository

## Usage 

1.  Navigate to the directory where you cloned in this repository
2.  either run `./install_script` or `bash install_script` from the **padawaninstalls** 
    directory 
    * if you would like, you can specify an install directory as the first parameter of 
    the script, but be sure not to include a trailing slash. See example below: 

    ```bash
    ./install_script.sh /home/<username>/developerlevel
    ```

_if you do not specify a directory as a parameter, the script will ask you for_ 
_a directory and offer you a default option_

## Docker Help

Here are some helpful docker commands to see what's going on in the containers, or see
what's running and get rid them if you need to. 

```bash

docker ps # shows all running containers
docker ps -a # shows all the containers, runnning and stopped
docker kill <container id / container name> # kill a single running container 
docker kill $(docker ps -q)  # kill all the running containers 
docker kill $(docker ps -q) && docker container prune -f  # kill all the running containers, 
# and get rid of any stopped containers without prompting 
docker logs -f <container id / container name> # follow the logs of a container in a terminal window
docker logs <container id / container name> # look at the most recent logs of a container
man docker    # check out the man page 
docker --help # docker help page 

```

## Known Issues 

1. the aarc containers are not properly raising from the `feature/DevDocker` 
branch that this script uses.  There is an update to aarc waiting to be reviewed 
that should resolve this issue, 
ref [paladinarcher/aarc PR #14](https://github.com/paladinarcher/aarc/pull/14)
