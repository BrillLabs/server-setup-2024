#!/bin/bash

set_mysql_iptable_for_ip_or_subnet(){
    echo -n " Setting MYSQL/MariaDB IPtable for ip or subnet..."
    echo -n " Type your subnet or ip, e.g 10.0.0.0/24 or 10.0.0.1/32 : "; read subnet
    iptables -A INPUT -p tcp -s $subnet --dport 3306 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 3306 -m conntrack --ctstate ESTABLISHED -j ACCEPT
    service netfilter-persistent start
    invoke-rc.d netfilter-persistent save
    netfilter-persistent save
    netfilter-persistent reload
}


set_mysql_iptable_for_ip_or_subnet