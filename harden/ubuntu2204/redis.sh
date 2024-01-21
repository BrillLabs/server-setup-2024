#!/bin/bash

set_redis_iptable_for_ip_or_subnet(){
    echo -n " Setting REDIS IPtable for ip or subnet..."
    echo -n " Type your subnet or ip, e.g 10.0.0.0/24 or 10.0.0.1/32 : "; read subnet
    iptables -A INPUT -s $subnet -p tcp -m tcp --dport 6379 -j ACCEPT
    iptables -A INPUT -p tcp -m tcp --dport 6379 -j DROP
    service netfilter-persistent start
    invoke-rc.d netfilter-persistent save
    netfilter-persistent save
    netfilter-persistent reload
}


set_redis_iptable_for_ip_or_subnet