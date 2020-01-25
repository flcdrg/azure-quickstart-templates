#!/bin/sh

# Install Build Tools
sudo /bin/date +%H:%M:%S > /home/$5/install.progress.txt

echo "ooooo      FULL INSTALL      ooooo" >> /home/$5/install.progress.txt

echo "Installing prerequisites" >> /home/$5/install.progress.txt

echo "apt-get update"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg-agent

echo "add-apt-repository docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "add-apt-repository git"
sudo add-apt-repository ppa:git-core/ppa -y

# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

echo "add-apt-repository universe"

# Enable the "universe" repositories
sudo add-apt-repository universe -y

sudo apt-get update

# Install Docker Engine and Compose
echo "Installing Docker Engine and Compose" >> /home/$5/install.progress.txt
echo "Docker"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo service docker start
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker $5

sudo curl -L https://github.com/docker/compose/releases/download/1.25.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

# Git
echo "Installing Git" >> /home/$5/install.progress.txt
echo "Git"
sudo apt-get install -y git

# PowerShell
echo "Installing PowerShell Core" >> /home/$5/install.progress.txt
echo "PowerShell"
# Install PowerShell
sudo apt-get install -y powershell

# Download VSTS build agent
echo "Downloading VSTS Build agent package" >> /home/$5/install.progress.txt
echo "Azure Pipelines"
sudo -u $5 mkdir /home/$5/downloads

cd /home/$5/downloads

sudo -u $5 wget -nv https://vstsagentpackage.azureedge.net/agent/2.163.1/vsts-agent-linux-x64-2.163.1.tar.gz

sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

echo "Installing VSTS Build agent package" >> /home/$5/install.progress.txt

# Install VSTS agent
sudo -u $5 mkdir /home/$5/vsts-agent
cd /home/$5/vsts-agent
sudo -u $5 tar xzf /home/$5/downloads/vsts-agent-linux*

sudo ./bin/installdependencies.sh

echo "LANG=en_US.UTF-8" > .env
echo "export LANG=en_US.UTF-8" >> /home/$5/.bashrc
export LANG=en_US.UTF-8

# HACK - only needed if .NET and Ruby/Rails are installed
# sudo -u $5 echo $PATH:/home/$5/lib/dotnet:/home/$5/.rvm/bin > /home/$5/vsts-agent/.path

# HACK - Remove NODE_ENV=production from service template file
sudo sed -i 's,NODE_ENV=production,,g' ./bin/vsts.agent.service.template

echo URL: $1 > /home/$5/vsts.install.log.txt 2>&1
echo PAT: HIDDEN >> /home/$5/vsts.install.log.txt 2>&1
echo Pool: $3 >> /home/$5/vsts.install.log.txt 2>&1
echo Agent: $4 >> /home/$5/vsts.install.log.txt 2>&1
echo User: $5 >> /home/$5/vsts.install.log.txt 2>&1
echo =============================== >> /home/$5/vsts.install.log.txt 2>&1

echo Running Agent.Listener >> /home/$5/vsts.install.log.txt 2>&1

# Create work directory on second disk
sudo mkdir /mnt/agent_work
sudo setfacl -m user:vstsBuild:rwx /mnt/agent_work

sudo -u $5 -E bin/Agent.Listener configure --unattended --replace --acceptteeeula --url $1 --auth PAT --token $2 --pool "$3" --work "/mnt/agent_work"  >> /home/$5/vsts.install.log.txt 2>&1
echo =============================== >> /home/$5/vsts.install.log.txt 2>&1
echo Running ./svc.sh install >> /home/$5/vsts.install.log.txt 2>&1
sudo -E ./svc.sh install $5 >> /home/$5/vsts.install.log.txt 2>&1
echo =============================== >> /home/$5/vsts.install.log.txt 2>&1
echo Running ./svc.sh start >> /home/$5/vsts.install.log.txt 2>&1


sudo -E ./svc.sh start >> /home/$5/vsts.install.log.txt 2>&1
echo =============================== >> /home/$5/vsts.install.log.txt 2>&1

sudo chown -R $5.$5 .*

echo "ALL DONE!" >> /home/$5/install.progress.txt
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt
