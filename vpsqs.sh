#!/bin/bash
# Script to Harden Security on VPS server with CentOS 7
# This VPS Server Hardening script is designed to be run on new VPS deployments to simplify a lot of the
# basic hardening that can be done to protect your server. I assimilated several design ideas from AMega's
# VPS hardening script which I found on Github seemingly abandoned. I am very happy to finish it.



#  and Begin
clear
echo "---------------------------------------------------- "
echo " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY "
echo "---------------------------------------------------- "
echo "------- install some stuff VPS Hardening Script --------- "
echo "----------------------------------------------------"
sleep 2
clear


echo ''
echo 'Install QEMU guest agent tools'
echo '------------------------------------------------'
# Install 
sudo yum install -y qemu-guest-agent


#########################
## CHECK & CREATE SWAP ##
#########################




# Check for and create swap file if necessary
	echo "------------------------------------------------- "
	echo " `date +%m.%d.%Y_%H:%M:%S` : CHECK FOR AND CREATE SWAP "
	echo "-------------------------------------------------"

# Check for swap file - if none, create one
swaponState=$(swapon -s)
if [[ -n $swaponState ]]
then
clear
		echo "---------------------------------------------------- "
		echo " `date +%m.%d.%Y_%H:%M:%S` : Swap exists- No changes made "
		echo "----------------------------------------------------" 
		sleep 2
	else
	    
clear
echo ''
echo 'This script will create swap file on your server'
echo '------------------------------------------------'
read -p "Swap size (Mb): " swapSizeValue
read -p "Swappiness value (1-100): " swappinessValue

clear
echo 'Enabling swap file in progress..Please wait'

# Create swap file
sudo cd /var
sudo touch swap.img
sudo chmod 600 swap.img

# Set swap size
sudo dd if=/dev/zero of=/var/swap.img bs=1024 count="${swapSizeValue}k"

# Prepare the disk image
sudo mkswap /var/swap.img

# Enable swap file
sudo swapon /var/swap.img

# Mount swap on reboot
echo "/var/swap.img    none    swap    sw    0    0" >> /etc/fstab

# Change swappiness value
sudo sysctl -w vm.swappiness=30

#Final output
clear
echo "Swap file with size $swapSizeValue Mb  has been created successfully"
sudo free | grep Swap

echo 'Swapines value'
sudo sysctl -a | grep vm.swappiness
clear
		echo "-------------------------------------------------- "
		echo " `date +%m.%d.%Y_%H:%M:%S` : SWAP CREATED SUCCESSFULLY "
		echo "------>    $swapSizeValue Mb    <------- "
		echo "--------------------------------------------------"
		sleep 2
	fi




##############
##EnableCron##
##############
#Autoupdate CentOS 7 with CRON
#Description: This script will install CRON on your server


clear

echo 'Installing CRON..'
# Install CRON
sudo yum -y install yum-cron
sudo chkconfig yum-cron on

sudo service yum-cron start

#Final output
clear
echo 'CRON has been successfully installed and started'
echo 'You can edit CRON config in /etc/yum/yum-cron.conf'
echo 'Do not forget to restart CRON service after editing config' 
echo "CRON has been successfully installed and started"
sleep 2
clear

######################
## UPDATE & UPGRADE ##
######################


# NOTE I learned the hard way that you must put a "\" BEFORE characters "\" and "`"
printf "  ___  ____    _   _           _       _ \n"
printf " / _ \/ ___|  | | | |_ __   __| | __ _| |_ ___ \n"
printf "| | | \\___ \\  | | | | '_ \\ / _\` |/ _\` | __/ _ \\ \n"
printf "| |_| |___) | | |_| | |_) | (_| | (_| | ||  __/ \n"
printf " \___/|____/   \___/| .__/ \__,_|\__,_|\__\___| \n"
printf "                    |_| \n"
echo "---------------------------------------------------- "
echo " `date +%m.%d.%Y_%H:%M:%S` : INITIATING SYSTEM UPDATE "
echo "---------------------------------------------------- "
sleep 2


clear

echo 'This script will help you to configure your server'
echo '---------------------------------------------'
echo 'Steps:'
echo "STEP 1: Update the system"
echo "STEP 2: Create New User"
echo "STEP 3: Add Public Key Authentication"
echo "STEP 4: Configuring SSH"
echo "STEP 5: Configuring a Basic Firewall"
echo "STEP 6: Configuring Timezones and NTP"
echo '---------------------------------------------'
echo "ATTENTION!!!"
echo 'This script will disable root login'
echo 'Also this script will disable authentication by password'
echo 'Only authentication by ssh key will be allowed'
echo '---------------------------------------------'
sleep 1
clear

#STEP 1 - Update the system
echo "GET READY TO WAIT: System Update " 

sudo yum -y update

clear
echo "System has been updated successfully"
sleep 1
clear

#STEP 2 - Create New User
		echo "-------------------------------------------------- "
		echo " `date +%m.%d.%Y_%H:%M:%S` :  CREATE A NEW ADMIN USER "
		echo "--------------------------------------------------"
		sleep 2

echo "Create New User " 

read -p "Enter new username (e.g. admin): " newUser
#Create User
echo "I am creating ${newUser}"
sudo adduser "${newUser}"
sudo passwd "${newUser}"
#Grant new user the root privileges
usermod -a -G wheel "${newUser}"
#Dont use this below why is it even in here
#sudo passwd -a "${newUser}" wheel

mkdir /home/${newUser}/.ssh
chmod 700 /home/${newUser}/.ssh
touch /home/${newUser}/.ssh/authorized_keys 
chown ${newUser}:${newUser} /home/${newUser}/.ssh -R
chmod 600 /home/${newUser}/.ssh/authorized_keys
service sshd restart
clear


clear
echo "User '${newUser}' with the root privileges has been created"
sleep 1
		echo "---------------------------------------------------- "
		echo " `date +%m.%d.%Y_%H:%M:%S` : SSH CHANGES "
		echo "----------------------------------------------------" 
		sleep 2



echo 'FOR REAL THOUGH, ANYTHING AFTER THIS '
echo 'CHANGES DEFAULT PORT AND DISABLES ROOT.'
echo ' --=Make sure you have KeyBox already setup=-- '
		sleep 4
echo 'Abort with CTRL+C'
echo 'PRESS ANY KEY TO CONTINUE'
read -n 1 -s
clear




#STEP 4 - Configuring SSH
echo "STEP 4: Configuring SSH " 
read -p "Enter new SSH port (47979-65536): " newSSHPort

#Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config_BACKUP

#Change SSH port
sudo sed -i "/#Port 22/a Port ${newSSHPort}" /etc/ssh/sshd_config
sudo service sshd restart
sleep 1
clear







#To explicitly disallow remote login from accounts with empty passwords, add or correct the following line in /etc/ssh/sshd_config:

#PermitEmptyPasswords no

#Any accounts with empty passwords should be disabled immediately.
#Also, PAM configuration should prevent users from being able to assign themselves empty passwords. 

grep -qi ^PermitEmptyPasswords /etc/ssh/sshd_config && \
  sed -i "s/PermitEmptyPasswords.*/PermitEmptyPasswords no/gI" /etc/ssh/sshd_config
if ! [ $? -eq 0 ]; then
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
fi






#To ensure users are not able to present environment options to the SSH daemon, add or correct the following line in /etc/ssh/sshd_config:

#PermitUserEnvironment no

grep -qi ^PermitUserEnvironment /etc/ssh/sshd_config && \
  sed -i "s/PermitUserEnvironment.*/PermitUserEnvironment no/gI" /etc/ssh/sshd_config
if ! [ $? -eq 0 ]; then
    echo "PermitUserEnvironment no" >> /etc/ssh/sshd_config
fi





#Limit the ciphers to those algorithms which are FIPS-approved. Counter (CTR) mode is also preferred over cipher-block chaining (CBC) mode. 
#The following line in /etc/ssh/sshd_config demonstrates use of FIPS-approved ciphers:

#Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc

#The man page sshd_config(5) contains a list of supported ciphers. 

grep -qi ^Ciphers /etc/ssh/sshd_config && \
  sed -i "s/Ciphers.*/Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc/gI" /etc/ssh/sshd_config
if ! [ $? -eq 0 ]; then
    echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc" >> /etc/ssh/sshd_config
fi







#Restrict Root Login
sudo sed -i "/#PermitRootLogin yes/a PermitRootLogin no" /etc/ssh/sshd_config

#Disable authentication by password and enable authentication by ssh key
sudo sed -i "/#RSAAuthentication yes/a RSAAuthentication yes" /etc/ssh/sshd_config
sudo sed -i "/#PubkeyAuthentication yes/a PubkeyAuthentication yes" /etc/ssh/sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

sudo systemctl reload sshd.service

clear
echo "SSH config has been HARDENED successfully"
sleep 3
clear
		echo "-------------------------------------------------- "
		echo " `date +%m.%d.%Y_%H:%M:%S` :  I didnt start the  "
		echo "--------------------------------------------------"
		sleep 1

#STEP 5 - Configuring a Basic Firewall
echo "STEP 5: Configuring a Basic Firewall " 

echo "Check to install FIREWALLD"
sleep 1

sudo yum install firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld


#If port SSH has NOT changed
#sudo firewall-cmd --permanent --add-service=ssh

#If port SSH has BEEN changed
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port="${newSSHPort}/tcp"
#HTTP
sudo firewall-cmd --permanent --add-service=http
#HTTPS
sudo firewall-cmd --permanent --add-service=https
#ADD MORE BELOW !!!!!!!!!!!!!!!!



#Reload firewall
sudo firewall-cmd --reload

sudo systemctl enable firewalld

#firewall-cmd --list-ports

echo "Firewall has been updated successfully"
sleep 1
clear

#STEP before 6 - Fail2Ban
echo "Install Fail2Ban"
sudo yum -y install epel-release
sudo yum -y install fail2ban

#Create the Config file
sudo touch /etc/fail2ban/jail.local

#Add the following:
echo "[sshd]">>/etc/fail2ban/jail.local
echo "enabled = true">>/etc/fail2ban/jail.local
echo "banaction = iptables-multiport">>/etc/fail2ban/jail.local
echo "port = ${newSSHPort}">>/etc/fail2ban/jail.local
echo "logpath = /var/log/auth.log">>/etc/fail2ban/jail.local
echo "maxretry = 10">>/etc/fail2ban/jail.local
echo "findtime = 43200">>/etc/fail2ban/jail.local
echo "bantime = 86400">>/etc/fail2ban/jail.local

#Then fire up fail2ban
systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sleep 1
clear

#STEP 6 - Configuring Timezones and NTP
echo "STEP 6: Configuring Timezones and NTP " 

#Timezone
read -p "Enter server timezone (e.g. America/Chicago): " serverTimezone
#sudo timedatectl list-timezones
sudo timedatectl set-timezone "${serverTimezone}"

#timedatectl -> check current settings

#NTP (Network Time Protocol Synchronization)
echo "Enable NTP"

sudo yum -y install ntp
sudo systemctl start ntpd
sudo systemctl enable ntpd

clear
echo "Network Time Protocol Synchronization (NTP) has been successfully installed and enabled"

#Final output
echo '-------------------------------------------------------'
echo 'Initial server setup has been completed successfully'
echo '-------------------------------------------------------'
echo 'Details:'
echo '1. System has been updated'
echo '2. CRON has been installed and started'
echo "3. User ${newUser} with the root privileges has been created"
echo '4. Public SSH key for new user has been added successfully'
echo '5. SSH config has been updated:'
echo "  - New SSH port is ${newSSHPort}"
echo '  - Root login has been disabled'
echo '  - Authentication by password has been disabled'
echo '  - SSH config backup: /etc/ssh/sshd_config_BACKUP'
echo '6. Firewall has been enabled'
echo '6. Firewall rules has been updated'
echo '7. Server timezone has been updated'
echo '8. Network Time Protocol Synchronization (NTP) has been enabled'
echo '---------------------------------------------'
