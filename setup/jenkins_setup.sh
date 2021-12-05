#! /usr/bin/bash
# bash script setup jenkins 

# Install Open JDK, Jenkins and Apache
echo "Install Open JDK, Jenkins and Apache"
wget -qO - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

sudo apt-get update
sudo apt install openjdk-11-jdk jenkins apache2 -y
sleep 1

# then start botj apache and jenkins
sudo systemctl start apache2
sudo systemctl start jenkins

# add Jenkins web apache2 config
echo "adding and symlinking config /etc/apache2/sites-available/jenkins"
sudo wget https://github.com/goodmeow/myscript/raw/master/ci/jenkins/jenkins.conf -P /etc/apache2/sites-available/
sudo chmod 644 /etc/apache2/sites-available/jenkins.conf

# a2enmod
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2ensite jenkins
sudo systemctl restart apache2
sudo systemctl restart jenkins