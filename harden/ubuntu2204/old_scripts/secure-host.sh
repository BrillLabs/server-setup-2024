#!/bin/bash

# JShielder v2.3
# Deployer for Ubuntu Server 20.01


source helpers.sh

##############################################################################################################

f_banner(){
echo
echo "SECURING UBUNTU 20.01"
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


##############################################################################################################

# Configure Hostname
config_host() {
echo -n " Â¿Do you Wish to Set a HostName? (y/n): "; read config_host
if [ "$config_host" == "y" ]; then
    serverip=$(__get_ip)
    echo " Type a Name to Identify this server :"
    echo -n " (For Example: myserver): "; read host_name
    echo -n " Â¿Type Domain Name?: "; read domain_name
    echo $host_name > /etc/hostname
    hostname -F /etc/hostname
    echo "127.0.0.1    localhost.localdomain      localhost" >> /etc/hosts
    echo "$serverip    $host_name.$domain_name    $host_name" >> /etc/hosts
    #Creating Legal Banner for unauthorized Access
    echo ""
    echo "Creating legal Banners for unauthorized access"
    spinner
    cat templates/motd > /etc/motd
    cat templates/motd > /etc/issue
    cat templates/motd > /etc/issue.net
    sed -i s/server.com/$host_name.$domain_name/g /etc/motd /etc/issue /etc/issue.net
    echo "OK "
fi
    say_done
}

##############################################################################################################

# Configure TimeZone
config_timezone(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m We will now Configure the TimeZone"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   sleep 10
   dpkg-reconfigure tzdata
   say_done
}

##############################################################################################################

# Update System, Install sysv-rc-conf tool
update_system(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Updating the System"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   apt update
   apt upgrade -y
   apt dist-upgrade -y
   apt install iptables-persistent
   say_done
}


##############################################################################################################

# Setting a more restrictive UMASK
restrictive_umask(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Setting UMASK to a more Restrictive Value (027)"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   spinner
   cp templates/login.defs /etc/login.defs
   echo ""
   echo "OK"
   say_done
}

#############################################################################################################

#Disabling Unused Filesystems

unused_filesystems(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Disabling Unused FileSystems"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   spinner
   echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install hfs /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install hfsplus /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install vfat /bin/true" >> /etc/modprobe.d/CIS.conf
   echo " OK"
   say_done
}

##############################################################################################################

uncommon_netprotocols(){
   clear
   f_banner
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo -e "\e[93m[+]\e[00m Disabling Uncommon Network Protocols"
   echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
   echo ""
   spinner
   echo "install dccp /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install sctp /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install rds /bin/true" >> /etc/modprobe.d/CIS.conf
   echo "install tipc /bin/true" >> /etc/modprobe.d/CIS.conf
   echo " OK"
   say_done

}

##############################################################################################################

# Create Privileged User
admin_user(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m We will now Create a New User"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Type the new username: "; read username
    adduser $username
    usermod -aG sudo $username
    chage -I -1 -m 0 -M 99999 -E -1 $username
    say_done
}


##############################################################################################################

# Instruction to Generate RSA Keys
rsa_keygen(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Instructions to Generate an RSA KEY PAIR"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    serverip=$(__get_ip)
    echo " *** IF YOU DONT HAVE A PUBLIC RSA KEY, GENERATE ONE ***"
    echo "     Follow the Instruction and Hit Enter When Done"
    echo "     To receive a new Instruction"
    echo " "
    echo "    RUN THE FOLLOWING COMMANDS"
    echo -n "     a) ssh-keygen -t rsa -b 4096 "; read foo1
    echo -n "     b) cat /home/$username/.ssh/id_rsa.pub >> /home/$username/.ssh/authorized_keys "; read foo2
    say_done
}


##############################################################################################################

# Move the Generated Public Key
rsa_keycopy(){
    echo " Run the Following Command to copy the Key"
    echo " Press ENTER when done "
    echo " ssh-copy-id -i $HOME/.ssh/id_rsa.pub $username@$serverip "
    say_done
}

##############################################################################################################

#Securing /tmp Folder
secure_tmp(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Securing /tmp Folder"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo -n " ¿Did you Create a Separate /tmp partition during the Initial Installation? (y/n): "; read tmp_answer
  if [ "$tmp_answer" == "n" ]; then
      echo "We will create a FileSystem for the /tmp Directory and set Proper Permissions "
      spinner
      dd if=/dev/zero of=/usr/tmpDISK bs=1024 count=2048000
      mkdir /tmpbackup
      cp -Rpf /tmp /tmpbackup
      mount -t tmpfs -o loop,noexec,nosuid,rw /usr/tmpDISK /tmp
      chmod 1777 /tmp
      cp -Rpf /tmpbackup/* /tmp/
      rm -rf /tmpbackup
      echo "/usr/tmpDISK  /tmp    tmpfs   loop,nosuid,nodev,noexec,rw  0 0" >> /etc/fstab
      sudo mount -o remount /tmp
      say_done
  else
      echo "Nice! Remember to set proper permissions in /etc/fstab"
      echo ""
      echo "Example:"
      echo ""
      echo "/dev/sda4   /tmp   tmpfs  loop,nosuid,noexec,rw  0 0 "
      say_done
  fi
}

##############################################################################################################

# Secure SSH
secure_ssh(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Securing SSH"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Securing SSH..."
    spinner
    sed s/USERNAME/$username/g templates/sshd_config > /etc/ssh/sshd_config; echo "OK"
    chattr -i /home/$username/.ssh/authorized_keys
    service ssh restart
    say_done
}


##############################################################################################################

# Set IPTABLES Rules
set_iptables(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Setting IPTABLE RULES"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Setting Iptables Rules..."
    spinner
    sh templates/iptables.sh
    cp templates/iptables.sh /etc/init.d/
    chmod +x /etc/init.d/iptables.sh
    ln -s /etc/init.d/iptables.sh /etc/rc2.d/S99iptables.sh
    say_done
}

##############################################################################################################

# Set CUSTOM IPTABLES Rules
## https://dzone.com/articles/hardening-an-aws-ec2-instance-1

set_custom_iptables_rules(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Setting CUSTOM IPTABLE RULES"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Setting Iptables Rules..."
    spinner
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -j LOG
    iptables -A FORWARD -j LOG
    iptables -A INPUT -i lo -p all -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type 13 -j DROP
    iptables -A INPUT -p icmp --icmp-type 17 -j DROP
    iptables -A INPUT -p icmp --icmp-type 14 -j DROP
    iptables -A INPUT -p icmp -m limit --limit 1/second -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
    iptables -A INPUT   -m recent --name portscan --rcheck --seconds 86400 -j DROP
    iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP
    iptables -A INPUT   -m recent --name portscan --remove
    iptables -A FORWARD -m recent --name portscan --remove
    # iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
    # iptables -A INPUT   -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
    # iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "Portscan:"
    # iptables -A FORWARD -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
    iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 2222 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type 0 -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT
    iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
    iptables -A OUTPUT -p tcp -m tcp --dport 2222 -j ACCEPT
    iptables -A INPUT -p tcp --syn --dport 2222 -m connlimit --connlimit-above 3 -j REJECT
    iptables -A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
    iptables -A FORWARD -j REJECT
    service netfilter-persistent start
    invoke-rc.d netfilter-persistent save
    netfilter-persistent save
    netfilter-persistent reload
    say_done
}

set_mysql_iptable_for_ip_or_subnet(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Set MYSQL IPtable for subnet"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Setting MYSQL IPtable for ip or subnet..."
    echo -n " Type your subnet or ip, e.g 10.0.0.0/24 or 10.0.0.1/32 : "; read subnet
    spinner
    iptables -A INPUT -p tcp -s $subnet --dport 3306 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 3306 -m conntrack --ctstate ESTABLISHED -j ACCEPT
    service netfilter-persistent start
    invoke-rc.d netfilter-persistent save
    netfilter-persistent save
    netfilter-persistent reload
    say_done
}

set_redis_iptable_for_ip_or_subnet(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Set REDIS IPtable for subnet"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " Setting REDIS IPtable for ip or subnet..."
    echo -n " Type your subnet or ip, e.g 10.0.0.0/24 or 10.0.0.1/32 : "; read subnet
    spinner
    iptables -A INPUT -s $subnet -p tcp -m tcp --dport 6379 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 6379 -j DROP
    service netfilter-persistent start
    invoke-rc.d netfilter-persistent save
    netfilter-persistent save
    netfilter-persistent reload
    say_done
}


##############################################################################################################

# Install fail2ban

set_custom_hosts_allow_rules(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Adding hosts.allow rules"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "sshd: ALL"  >> /etc/hosts.allow
    echo "sshd: 194.72.132.72/29" >> /etc/hosts.allow
    echo "sshd: 82.26.180.155" >> /etc/hosts.allow
    echo "sshd: 193.240.153.162/24" >> /etc/hosts.allow
    echo "sshd: 51.149.9.112/29" >> /etc/hosts.allow
    echo "sshd: 51.149.9.240/29" >> /etc/hosts.allow
    say_done
}

##############################################################################################################

# Install fail2ban
    # To Remove a Fail2Ban rule use:
    # iptables -D fail2ban-ssh -s IP -j DROP
install_fail2ban(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install sendmail
    apt install fail2ban
    say_done
}


##############################################################################################################

# Configure fail2ban
config_fail2ban(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Configuring Fail2Ban"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo " Configuring Fail2Ban......"
    spinner
    sed s/MAILTO/$inbox/g templates/fail2ban > /etc/fail2ban/jail.local
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf
    /etc/init.d/fail2ban restart
    say_done
}

##############################################################################################################

# Install Additional Packages
additional_packages(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Additional Packages"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Install tree............."; apt install tree
    echo "Install Vim.............."; apt install vim
    echo "Install Nano............."; apt install nano
    echo "Install DebSums.........."; apt install debsums
    echo "Install apt-show-versions"; apt install apt-show-versions
    say_done
}

##############################################################################################################

# Tune and Secure Kernel
tune_secure_kernel(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tuning and Securing the Linux Kernel"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo " Securing Linux Kernel"
    spinner
    echo "* hard core 0" >> /etc/security/limits.conf
    cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
    cp templates/ufw /etc/default/ufw
    sysctl -e -p
    say_done
}

##############################################################################################################

# Install RootKit Hunter
install_rootkit_hunter(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing RootKit Hunter"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Rootkit Hunter is a scanning tool to ensure you are you're clean of nasty tools. This tool scans for rootkits, backdoors and local exploits by running tests like:

          - MD5 hash compare
          - Look for default files used by rootkits
          - Wrong file permissions for binaries
          - Look for suspected strings in LKM and KLD modules
          - Look for hidden files
          - Optional scan within plaintext and binary files "
    sleep 1
    cd rkhunter-1.4.6/
    sh installer.sh --layout /usr --install
    cd ..
    rkhunter --update
    rkhunter --propupd
    echo ""
    echo " ***To Run RootKit Hunter ***"
    echo "     rkhunter -c --enable all --disable none"
    echo "     Detailed report on /var/log/rkhunter.log"
    say_done
}

##############################################################################################################

# Tuning
tune_nano_vim_bashrc(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Tunning bashrc, nano and Vim"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""

# Tune .bashrc
    echo "Tunning .bashrc......"
    spinner
    cp templates/bashrc-root /root/.bashrc
    cp templates/bashrc-user /home/$username/.bashrc
    chown $username:$username /home/$username/.bashrc
    echo "OK"


# Tune Vim
    echo "Tunning Vim......"
    spinner
    tunning vimrc
    echo "OK"


# Tune Nano
    echo "Tunning Nano......"
    spinner
    tunning nanorc
    echo "OK"
    say_done
}


##############################################################################################################

# Add Daily Update Cron Job
daily_update_cronjob(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Adding Daily System Update Cron Job"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Creating Daily Cron Job"
    spinner
    job="@daily apt update; apt dist-upgrade -y"
    touch job
    echo $job >> job
    crontab job
    rm job
    say_done
}

##############################################################################################################

# Install PortSentry
install_portsentry(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing PortSentry"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install portsentry
    mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf-original
    cp templates/portsentry /etc/portsentry/portsentry.conf
    sed s/tcp/atcp/g /etc/default/portsentry > salida.tmp
    mv salida.tmp /etc/default/portsentry
    /etc/init.d/portsentry restart
    say_done
}

##############################################################################################################

# Install and Configure Artillery
install_artillery (){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Cloning Repo and Installing Artillery"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    git clone https://github.com/BinaryDefense/artillery
    cd artillery/
    python setup.py
    cd ..
    echo ""
    echo "Setting Iptable rules for artillery"
    spinner
    for port in 22 1433 8080 21 5900 53 110 1723 1337 10000 5800 44443 16993; do
      echo "iptables -A INPUT -p tcp -m tcp --dport $port -j ACCEPT" >> /etc/init.d/iptables.sh
    done
    echo ""
    echo "Artillery configuration file is /var/artillery/config"
    say_done  
}

##############################################################################################################

# Additional Hardening Steps
additional_hardening(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Running additional Hardening Steps"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Running Additional Hardening Steps...."
    spinner
    echo tty1 > /etc/securetty
    chmod 0600 /etc/securetty
    chmod 700 /root
    chmod 600 /boot/grub/grub.cfg
    #Remove AT and Restrict Cron
    apt purge at
    apt install -y libpam-cracklib
    echo ""
    echo " Securing Cron "
    spinner
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
    echo ""
    echo -n " Do you want to Disable USB Support for this Server? (y/n): " ; read usb_answer
    if [ "$usb_answer" == "y" ]; then
       echo ""
       echo "Disabling USB Support"
       spinner
       echo "blacklist usb-storage" | sudo tee -a /etc/modprobe.d/blacklist.conf
       update-initramfs -u
       echo "OK"
       say_done
    else
       echo "OK"
       say_done
    fi
}

##############################################################################################################

# Install Unhide
install_unhide(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing UnHide"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Unhide is a forensic tool to find hidden processes and TCP/UDP ports by rootkits / LKMs or by another hidden technique."
    sleep 1
    apt -y install unhide
    echo ""
    echo " Unhide is a tool for Detecting Hidden Processes "
    echo " For more info about the Tool use the manpages "
    echo " man unhide "
    say_done
}

##############################################################################################################

# Install Tiger
#Tiger is and Auditing and Intrusion Detection System
install_tiger(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing Tiger"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Tiger is a security tool that can be use both as a security audit and intrusion detection system"
    sleep 1
    apt -y install tiger
    echo ""
    echo " For More info about the Tool use the ManPages "
    echo " man tiger "
    say_done
}

##############################################################################################################

#Install PSAD
#PSAD actively monitors firewall logs to determine if a scan or attack is taking place
install_psad(){
clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m Install PSAD"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo " PSAD is a piece of Software that actively monitors you Firewall Logs to Determine if a scan
       or attack event is in Progress. It can alert and Take action to deter the Threat

       NOTE:
       IF YOU ARE ONLY RUNNING THIS FUNCTION, YOU MUST ENABLE LOGGING FOR iptables

       iptables -A INPUT -j LOG
       iptables -A FORWARD -j LOG

       "
echo ""
echo -n " Do you want to install PSAD (Recommended)? (y/n): " ; read psad_answer
if [ "$psad_answer" == "y" ]; then
     echo -n " Type an Email Address to Receive PSAD Alerts: " ; read inbox1
     apt install psad
     sed -i s/INBOX/$inbox1/g templates/psad.conf
     sed -i s/CHANGEME/$host_name.$domain_name/g templates/psad.conf  
     cp templates/psad.conf /etc/psad/psad.conf
     psad --sig-update
     service psad restart
     echo "Installation and Configuration Complete"
     echo "Run service psad status, for detected events"
     echo ""
     say_done
else
     echo "OK"
     say_done
fi
}

##############################################################################################################


# Disable Compilers
disable_compilers(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Disabling Compilers"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo "Disabling Compilers....."
    spinner
    chmod 000 /usr/bin/as >/dev/null 2>&1
    chmod 000 /usr/bin/byacc >/dev/null 2>&1
    chmod 000 /usr/bin/yacc >/dev/null 2>&1
    chmod 000 /usr/bin/bcc >/dev/null 2>&1
    chmod 000 /usr/bin/kgcc >/dev/null 2>&1
    chmod 000 /usr/bin/cc >/dev/null 2>&1
    chmod 000 /usr/bin/gcc >/dev/null 2>&1
    chmod 000 /usr/bin/*c++ >/dev/null 2>&1
    chmod 000 /usr/bin/*g++ >/dev/null 2>&1
    spinner
    echo ""
    echo " If you wish to use them, just change the Permissions"
    echo " Example: chmod 755 /usr/bin/gcc "
    echo " OK"
    say_done
}


##############################################################################################################

# Additional Security Configurations
  #Enable Unattended Security Updates
  unattended_upgrades(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Unattended Security Updates"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo -n " ¿Do you Wish to Enable Unattended Security Updates? (y/n): "; read unattended
  if [ "$unattended" == "y" ]; then
      dpkg-reconfigure -plow unattended-upgrades
  else
      clear
  fi
}

##############################################################################################################

# Enable Process Accounting
enable_proc_acct(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Enable Process Accounting"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install acct
  touch /var/log/wtmp
  echo "OK"
}

##############################################################################################################

#Install and enable auditd

install_auditd(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing auditd"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install auditd

  # Using CIS Benchmark configuration
  
  #Ensure auditing for processes that start prior to auditd is enabled 
  echo ""
  echo "Enabling auditing for processes that start prior to auditd"
  spinner
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="audit=1"/g' /etc/default/grub
  update-grub

  echo ""
  echo "Configuring Auditd Rules"
  spinner

  cp templates/audit-CIS.rules /etc/audit/rules.d/audit.rules

  find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print \
  "-a always,exit -F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 \
  -k privileged" } ' >> /etc/audit/rules.d/audit.rules

  echo " " >> /etc/audit/rules.d/audit.rules
  echo "#End of Audit Rules" >> /etc/audit/rules.d/audit.rules
  echo "-e 2" >>/etc/audit/rules.d/audit.rules

  systemctl enable auditd.service
  service auditd restart
  echo "OK"
  say_done
}
##############################################################################################################

#Install and Enable sysstat

install_sysstat(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing and enabling sysstat"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  apt install sysstat
  sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat
  service sysstat start
  echo "OK"
  say_done
}

##############################################################################################################

#Install ArpWatch

install_arpwatch(){
  clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m ArpWatch Install"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo "ArpWatch is a tool for monitoring ARP traffic on System. It generates log of observed pairing of IP and MAC."
  echo ""
  echo -n " Do you want to Install ArpWatch on this Server? (y/n): " ; read arp_answer
  if [ "$arp_answer" == "y" ]; then
     echo "Installing ArpWatch"
     spinner
     apt install -y arpwatch
     systemctl enable arpwatch.service
     service arpwatch start
     echo "OK"
     say_done
  else
     echo "OK"
     say_done
  fi
} 

##############################################################################################################

file_permissions(){
 clear
  f_banner
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Setting File Permissions on Critical System Files"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  spinner
  sleep 2
  chmod -R g-wx,o-rwx /var/log/*

  chown root:root /etc/ssh/sshd_config
  chmod og-rwx /etc/ssh/sshd_config

  chown root:root /etc/passwd
  chmod 644 /etc/passwd

  chown root:shadow /etc/shadow
  chmod o-rwx,g-wx /etc/shadow

  chown root:root /etc/group
  chmod 644 /etc/group

  chown root:shadow /etc/gshadow
  chmod o-rwx,g-rw /etc/gshadow

  chown root:root /etc/passwd-
  chmod 600 /etc/passwd-

  chown root:root /etc/shadow-
  chmod 600 /etc/shadow-

  chown root:root /etc/group-
  chmod 600 /etc/group-

  chown root:root /etc/gshadow-
  chmod 600 /etc/gshadow-


  echo -e ""
  echo -e "Setting Sticky bit on all world-writable directories"
  sleep 2
  spinner

  df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

  echo " OK"
  say_done

}
##############################################################################################################

# Reboot Server
reboot_server(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Final Step"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    sed -i s/USERNAME/$username/g templates/texts/bye
    sed -i s/SERVERIP/$serverip/g templates/texts/bye
    cat templates/texts/bye
    echo -n " ¿Were you able to connect via SSH to the Server using $username? (y/n): "; read answer
    if [ "$answer" == "y" ]; then
        reboot
    else
        echo "Server will not Reboot"
        echo "Bye."
    fi
}

##################################################################################################################


##################################################################################################################

clear
f_banner
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
echo ""
echo "1. Secure environment"
echo "2. Set MYSQL IPtable for ip or subnet"
echo "3. Set Redis IPtable for ip or subnet"
echo "9. Exit"
echo

read choice

case $choice in

1)
check_root
install_dep
config_host
config_timezone
update_system
restrictive_umask
unused_filesystems
uncommon_netprotocols
admin_user
rsa_keygen
rsa_keycopy
secure_ssh
set_iptables
set_custom_iptables_rules
set_custom_hosts_allow_rules
install_fail2ban
config_fail2ban
additional_packages
tune_secure_kernel
install_rootkit_hunter
tune_nano_vim_bashrc
daily_update_cronjob
install_artillery
additional_hardening
install_unhide
install_tiger
install_psad
disable_compilers
secure_tmp
unattended_upgrades
enable_proc_acct
install_auditd
install_sysstat
install_arpwatch
file_permissions
reboot_server
;;

2)
check_root
set_mysql_iptable_for_ip_or_subnet
;;

3)
check_root
set_redis_iptable_for_ip_or_subnet
;;

4)
chmod +x deployment-setup.sh
./deployment-setup.sh
;;

9)
exit 0
;;

esac
##############################################################################################################