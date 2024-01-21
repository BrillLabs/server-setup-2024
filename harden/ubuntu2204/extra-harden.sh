#!/bin/bash

add_admin_user(){
    echo "Adding admin user..."
    echo -n " Type the new username: "; read username
    adduser $username
    usermod -aG sudo $username
    chage -I -1 -m 0 -M 99999 -E -1 $username
    echo "Done adding new user..."
}


ssh_key_for_admin_user()
{
    echo "Adding admin user ssh keys..."
    mkdir /home/$username/.ssh
    chmod 700 /home/$username/.ssh
    cp /root/.ssh/authorized_keys /home/$username/.ssh/authorized_keys
    chmod 600 /home/$username/.ssh/authorized_keys
    chown -R $username:$username /home/$username/.ssh
    echo "Done adding new admin sshkeys..."
}

# Disabling unused fileSystems
unused_filesystems(){
    echo "Disabling unused fileSystems..."
    echo "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install hfs /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install hfsplus /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install vfat /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "Done disabling unused fileSystems..."
}


# Disabling uncommon network protocols
uncommon_netprotocols(){
    echo "install dccp /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install sctp /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install rds /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "install tipc /bin/true" >> /etc/modprobe.d/CIS.conf
    echo "Done disabling uncommon network protocols..."
}


secure_ssh(){
    echo -n " Securing SSH..."
    sed s/USERNAME/$username/g templates/sshd_config > /etc/ssh/sshd_config; echo "OK"
    #Set the "immutable" attribute. Files with this attribute cannot be modified, deleted, or renamed, even by the root user.
    chattr -i /home/$username/.ssh/authorized_keys
    service ssh restart
    echo "Done securing ssh..."
}


set_basic_iptables(){
    clear
    echo "Setting Iptables rules..."
    sh templates/iptables.sh
    cp templates/iptables.sh /etc/init.d/
    chmod +x /etc/init.d/iptables.sh
    ln -s /etc/init.d/iptables.sh /etc/rc2.d/S99iptables.sh
    echo "Done setting Iptables rules..."
}


set_custom_iptables_rules(){
    clear
    echo "Setting Iptables custom rules..."
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
    echo "Done setting Iptables custom rules..."
}

set_custom_hosts_allow_rules(){
    clear
    echo "Adding hosts.allow rules..."
    echo "sshd: ALL"  >> /etc/hosts.allow
    echo "sshd: 194.72.132.72/29" >> /etc/hosts.allow
    echo "Done adding hosts.allow rules"
}


# Configure fail2ban
config_fail2ban(){
    clear
    echo "Configuring Fail2Ban......"
    apt install sendmail
    apt install fail2ban
    sed s/MAILTO/$inbox/g templates/fail2ban > /etc/fail2ban/jail.local
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.conf
    /etc/init.d/fail2ban restart
    echo "Done configuring Fail2Ban......"
}


# Secure Kernel
secure_kernel(){
    clear
    echo " Securing Linux Kernel"
    echo "* hard core 0" >> /etc/security/limits.conf
    cp templates/sysctl.conf /etc/sysctl.conf; echo " OK"
    cp templates/ufw /etc/default/ufw
    sysctl -e -p
    echo "Done securing Linux Kernel"
}


daily_update_cronjob(){
    clear
    echo -e "Adding daily system update cron job"
    echo ""
    echo "Creating Daily Cron Job"
    job="@daily apt update; apt dist-upgrade -y"
    touch job
    echo $job >> job
    crontab job
    rm job
    echo "Done cron job"
}


# Install PortSentry
install_portsentry(){
    clear
    echo -e "Installing PortSentry"
    echo ""
    apt install portsentry
    mv /etc/portsentry/portsentry.conf /etc/portsentry/portsentry.conf-original
    cp templates/portsentry /etc/portsentry/portsentry.conf
    sed s/tcp/atcp/g /etc/default/portsentry > exit.tmp
    mv exit.tmp /etc/default/portsentry
    /etc/init.d/portsentry restart
    echo "Done installing PortSentry"
}


# Install RootKit Hunter
install_rootkit_hunter(){
    clear
    echo -e "Installing RootKit Hunter"
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
    echo "Done installing RootKit Hunter"
}


# Additional Hardening Steps
additional_hardening(){
    clear
    echo -e "Running additional Hardening Steps"
    echo ""
    echo "Running Additional Hardening Steps...."
    echo tty1 > /etc/securetty
    chmod 0600 /etc/securetty
    chmod 700 /root
    chmod 600 /boot/grub/grub.cfg
    #Remove AT and Restrict Cron
    apt purge at
    apt install -y libpam-cracklib
    echo ""
    echo " Securing Cron "
    touch /etc/cron.allow
    chmod 600 /etc/cron.allow
    awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
    echo ""
    echo -n " Do you want to Disable USB Support for this Server? (y/n): " ; read usb_answer
    if [ "$usb_answer" == "y" ]; then
       echo ""
       echo "Disabling USB Support"
       echo "blacklist usb-storage" | sudo tee -a /etc/modprobe.d/blacklist.conf
       update-initramfs -u
    fi
    echo "Done additional hardening..."
}


# Install Unhide
install_unhide(){
    clear
    echo -e "Installing UnHide"
    echo ""
    echo "Unhide is a forensic tool to find hidden processes and TCP/UDP ports by rootkits / LKMs or by another hidden technique."
    sleep 1
    apt -y install unhide
    echo ""
    echo " Unhide is a tool for Detecting Hidden Processes "
    echo " For more info about the Tool use the manpages "
    echo " man unhide "
}


#Tiger is and Auditing and Intrusion Detection System
install_tiger(){
    clear
    echo -e "Installing Tiger"
    echo ""
    echo "Tiger is a security tool that can be use both as a security audit and intrusion detection system"
    sleep 1
    apt -y install tiger
    echo ""
    echo " For More info about the Tool use the ManPages "
    echo " man tiger "
}

# Enable Process Accounting
enable_proc_acct(){
    clear
    echo "Enable process accounting..."
    echo ""
    apt install acct
    touch /var/log/wtmp
    echo "Done configuring acct......"
}


#Install and enable auditd
install_auditd(){
  clear
  echo "Installing auditd"
  echo ""
  apt install auditd
  
  #Ensure auditing for processes that start prior to auditd is enabled 
  echo ""
  echo "Enabling auditing for processes that start prior to auditd"
  
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="audit=1"/g' /etc/default/grub
  update-grub

  echo ""
  echo "Configuring Auditd Rules"

  cp templates/audit-CIS.rules /etc/audit/rules.d/audit.rules
  find / -xdev \( -perm -4000 -o -perm -2000 \) -type f | awk '{print \
  "-a always,exit -F path=" $1 " -F perm=x -F auid>=1000 -F auid!=4294967295 \
  -k privileged" } ' >> /etc/audit/rules.d/audit.rules

  echo " " >> /etc/audit/rules.d/audit.rules
  echo "#End of Audit Rules" >> /etc/audit/rules.d/audit.rules
  echo "-e 2" >>/etc/audit/rules.d/audit.rules

  systemctl enable auditd.service
  service auditd restart
  echo "Done installing auditd and configuring CIS level setting"
}


#Install and Enable sysstat
install_sysstat(){
  clear
  echo "Installing and enabling sysstat"
  echo ""
  apt install sysstat
  sed -i 's/ENABLED="false"/ENABLED="true"/g' /etc/default/sysstat
  service sysstat start
  echo "Done installing sysstat"
}

#Install ArpWatch
install_arpwatch(){
    clear
    echo -e "ArpWatch Install"
    echo ""
    echo -n " Do you want to Install ArpWatch on this Server? (y/n): " ; read arp_answer
    if [ "$arp_answer" == "y" ]; then
        echo "Installing ArpWatch"
        apt install -y arpwatch
        systemctl enable arpwatch.service
        service arpwatch start
        echo "Done installing Arpwatch"
    else
        echo "Done: Arpwatch not installed"
    fi
} 


file_permissions(){
    clear
    echo -e "Setting file permissions on critical system files"
    echo ""
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

    df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t

    echo "Done: Setting file permissions on critical system files"
}


#Securing /tmp Folder
secure_tmp_info(){
    echo "Securing /tmp Folder"
    echo "Remember to set proper permissions in /etc/fstab"
    echo ""
    echo "Example:"
    echo ""
    echo "/dev/sda4   /tmp   tmpfs  loop,nosuid,noexec,rw  0 0 "
}


add_admin_user
ssh_key_for_admin_user
unused_filesystems
uncommon_netprotocols
secure_ssh
set_basic_iptables
set_custom_iptables_rules
set_custom_hosts_allow_rules
config_fail2ban
secure_kernel
daily_update_cronjob
install_rootkit_hunter
additional_hardening
install_unhide
install_tiger
enable_proc_acct
install_portsentry
install_auditd
install_sysstat
install_arpwatch
file_permissions
secure_tmp_info