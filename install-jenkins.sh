#!/bin/bash

# Install Java
sudo apt-get update -y
sudo apt-get --assume-yes install openjdk-11-jre

PATH_NEW=${PATH}:/usr/lib/jbm/java-11-openjdk-amd64/bin

sudo echo 'JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"' > /etc/environment
sudo echo "PATH=${PATH_NEW}" >> /etc/environment

PATH=${PATH_NEW}
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/java"

# Install Jenkins

wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update -y
sudo apt-get install -y jenkins
