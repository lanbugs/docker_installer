#!/bin/bash

GREEN="\e[32m"
ENDCOLOR="\e[0m"

echo -e " ${GREEN}Welcome to Docker-CE installer for Ubuntu 18.04/20.04/22.04 ...${ENDCOLOR} "
echo -e " ${GREEN}---------------------------------------------------------------${ENDCOLOR} "
echo -e " ${GREEN}You will be asked for your sudo password if set.${ENDCOLOR} "

echo -e " ${GREEN}>>> Get repo update ...${ENDCOLOR} "
sudo apt -y update

echo -e " ${GREEN}>>> Install curl and wget ...${ENDCOLOR} "
sudo apt install -y curl wget

echo -e " ${GREEN}>>> Install helpers ...${ENDCOLOR} "
sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

echo -e " ${GREEN}>>> Remove old docker versions ...${ENDCOLOR} "
sudo apt remove docker docker-engine docker.io containerd runc

echo -e " ${GREEN}>>> Add repo key ...${ENDCOLOR} "
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg

echo -e " ${GREEN}>>> Add repo ...${ENDCOLOR} "
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

echo -e " ${GREEN}>>> Get repo updates ...${ENDCOLOR} "
sudo apt -y update

echo -e " ${GREEN}>>> Install docker ...${ENDCOLOR} "
sudo apt -y install docker-ce docker-ce-cli containerd.io

echo -e " ${GREEN}>>> Install last docker-compose ...${ENDCOLOR} "
curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url  | grep docker-compose-linux-x86_64 | cut -d '"' -f 4 | wget -qi -
chmod +x docker-compose-linux-x86_64
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

echo -e " ${GREEN}>>> Add current user to docker group ...${ENDCOLOR} "
sudo usermod -aG docker $USER

echo -e " ${GREEN}>>> Identify shell ...${ENDCOLOR} "
if [[ -v BASH ]];
then
  echo -e " ${GREEN}>>> It is bash, install bash completion definition for docker-compose ...${ENDCOLOR} "
  sudo curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
  source /etc/bash_completion.d/docker-compose
fi

echo -e " ${GREEN}--------------------------------------------${ENDCOLOR} "
echo -e " ${GREEN}------ FINISHED, HAVE FUN WITH DOCKER ------${ENDCOLOR} "
echo -e " ${GREEN}--------------------------------------------${ENDCOLOR} "

newgrp docker
