#!/bin/bash

# Deployment Laravel Setup for Ubuntu 18.02/20.01
# Follows: https://www.digitalocean.com/community/tutorials/automatically-deploy-laravel-applications-deployer-ubuntu
# Version 1.0

source helpers.sh

##############################################################################################################

f_banner(){
echo
echo "DEPLOYMENT SCRIPT FOR UBUNTU 18.04"
echo
echo

}

##############################################################################################################

# Check if running with root User

clear
f_banner


check_root() {
if [ "$USER" != "root" ]; then
	echo "Permission Denied"
	echo "Can only be run by root"
	exit
else
      clear
      f_banner
      cat templates/texts/welcome
fi
}

add_deployer_user() {
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Add Deployer user"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    spinner
	adduser deployer
	usermod -aG nginx deployer
    chfn -o umask=022 deployer
	cp templates/bashrc-deployer /home/deployer/.bashrc
    chown deployer:deployer /home/deployer/.bashrc
    echo "Your local machine will communicate with this server using SSH as well, so you should"
    echo "generate SSH keys for the Deployer user on your local machine and add the public key to this server."
    echo "Use option 5 to see the instruction"
}


add_app_folder() {
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Set up application forlder"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Type your application folder, e.g. /var/web/banglaplayer: "; read appdir
    spinner
	mkdir -p $appdir
	chown deployer:nginx $appdir
    chmod g+s $appdir
    sudo -u nginx stat $appdir
}


add_wordpress_folder_permission() {
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Set up Wordpress folder"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Type your application folder, e.g. /var/web/banglaplayer/: "; read appdir
    spinner
    # reset to safe defaults
    find $appdir -exec chown deployer:nginx {} \;
    find $appdir -type d -exec chmod 775 {} \;
    find $appdir -type f -exec chmod 664 {} \;

    # allow wordpress to manage wp-config.php (but prevent world access)
    chmod 640 $appdir/wp-config.php
}


set_up_deployer_user_git()
{
    su - deployer
    ssh-keygen -t rsa -b 4096
    cat ~/.ssh/id_rsa.pub
    echo "Copy the public key and add it to your Git repo so it is able to pull down repo"
}


instruction_for_generating_ssh_public_key_locally_for_deployer()
{
    echo "1. In your local machine where you will be deploying from, do the following:"
    echo "ssh-keygen -t rsa -b 4096 -f  ~/.ssh/deployer[CHOOSE_YOUR_OWN]"
    echo "2. Copy the public key"
    echo "cat ~/.ssh/deployer[CHOOSE_YOUR_OWN].pub"
    echo "3. On this server as the Deployer (su - deployer) user run the following:"
    echo "nano ~/.ssh/authorized_keys"
    echo "4. Restrict the permissions of the file:"
    echo "chmod 600 ~/.ssh/authorized_keys"
    echo "5. Exit"
    echo "6. Try to see if you can login as Deployer to using the set credential"
    echo "ssh deployer@this_server_ip_address  -i ~/.ssh/deployer[CHOOSE_YOUR_OWN] -p 2222"
    echo "7. After you have logged in as deployer, test the connection between this server and the Git server as well:"
    echo "ssh -T git@mygitserver.com"
    echo "8. Done"
    echo
}


##################################################################################################################

clear
f_banner
echo -e "\e[34m-------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
echo -e "\e[34m-------------------------------------------------------------------\e[00m"
echo ""
echo "1. Add Deployer user and create app folder and set permissions"
echo "2. Add Deployer user"
echo "3. Create app folder"
echo "4. Set up git Deployer will clone the Git repo to the production server using SSH"
echo "5. Install Docker Compose as app user"
echo "9. Exit"
echo

read choice

case $choice in

1)
check_root
add_deployer_user
add_app_folder
;;

2)
check_root
add_deployer_user
;;

3)
check_root
add_app_folder
;;

4)
check_root
set_up_deployer_user_git
;;

5)
instruction_for_generating_ssh_public_key_locally_for_deployer
;;

6)
add_wordpress_folder_permission
;;

9)
exit 0
;;

esac
##############################################################################################################