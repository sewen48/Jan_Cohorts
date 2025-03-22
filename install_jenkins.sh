#!/bin/bash

set -e  # Exit immediately if any command fails

# Update package list
sudo apt-get update -y

# Install Java SDK 17 (Recommended for latest Jenkins versions)
sudo apt-get install openjdk-17-jdk -y

# Remove old Jenkins key if exists
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc

# Add the new Jenkins key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add the Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists
sudo apt-get update -y

# Install Jenkins
sudo apt-get install jenkins -y

# Install Maven
sudo apt install maven -y

# Start and enable Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Output Jenkins initial admin password
echo "Jenkins installation complete!"
echo "Use the following password to unlock Jenkins:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

