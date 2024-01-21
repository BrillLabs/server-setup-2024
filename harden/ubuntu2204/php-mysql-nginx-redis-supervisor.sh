#!/bin/bash

# Deployment Laravel Setup for Ubuntu 18.02/20.01
# Follows: https://www.digitalocean.com/community/tutorials/automatically-deploy-laravel-applications-deployer-ubuntu
# Version 1.0

source helpers.sh

##############################################################################################################

f_banner(){
echo
echo "PHP, NGINX, REDIS, SUPERVISOR and MYSQL FOR UBUNTU 22.04"
echo
echo

}

##############################################################################################################

# Check if running with root User

clear
f_banner


##############################################################################################################

# Install, Configure and Optimize MySQL
install_secure_mysql(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing MySQL"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install mysql-server
    echo ""
    echo -n " configuring MySQL............ "
    spinner
    cp templates/mysql /etc/mysql/mysqld.cnf; echo " OK"
    mysql_secure_installation
    cp templates/usr.sbin.mysqld /etc/apparmor.d/local/usr.sbin.mysqld
    service mysql restart
    say_done
}

# Install, Configure and Optimize MariaDB
install_secure_mariadb(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing MariaDB"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    echo -n " configuring MariaDB............ "
    spinner
    apt install -y software-properties-common
    apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
    sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.6/ubuntu focal main'
    apt update && sudo apt install -y mariadb-server mariadb-client
    mv cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
    cp templates/mariadb /etc/mysql/my.cnf; echo " OK"
    mysql_secure_installation
    cp templates/usr.sbin.mysqld /etc/apparmor.d/local/usr.sbin.mysqld
    service mysql restart
    say_done
}


install_nginx_with_mods(){
    clear
    f_banner 
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing NginX Web Server with Mods"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    wget https://raw.githubusercontent.com/FuriousWarrior/NginxFastStart/master/nginx-autoinstall.sh
    chmod +x nginx-autoinstall.sh
    ./nginx-autoinstall.sh
    say_done
}


add_nginx_ensite(){
    clear
    f_banner 
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Add Ensite for Nginx"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    git clone https://github.com/perusio/nginx_ensite.git
    cd nginx_ensite
    sudo make install
    say_done
}



##############################################################################################################

# Install Nginx
install_nginx(){
  clear
  f_banner 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Installing NginX Web Server"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  echo "deb http://nginx.org/packages/ubuntu/ bionic nginx" >> /etc/apt/sources.list
  echo "deb-src http://nginx.org/packages/ubuntu/ bionic nginx" >> /etc/apt/sources.list
  curl -O https://nginx.org/keys/nginx_signing.key && apt-key add ./nginx_signing.key
  apt update
  apt install nginx
  say_done
}

##############################################################################################################

#Compile ModSecurity for NginX

compile_modsec_nginx(){
  clear
  f_banner 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Install Prerequisites and Compiling ModSecurity for NginX"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""

apt install bison flex make automake gcc pkg-config libtool doxygen git curl zlib1g-dev libxml2-dev libpcre3-dev build-essential libyajl-dev yajl-tools liblmdb-dev rdmacm-utils libgeoip-dev libcurl4-openssl-dev liblua5.2-dev libfuzzy-dev openssl libssl-dev

cd /opt/
git clone https://github.com/SpiderLabs/ModSecurity

cd ModSecurity
git checkout v3/master
git submodule init
git submodule update

./build.sh
./configure
make
make install

cd ..

nginx_version=$(dpkg -l |grep nginx | awk '{print $3}' | cut -d '-' -f1)

wget http://nginx.org/download/nginx-$nginx_version.tar.gz
tar xzvf nginx-$nginx_version.tar.gz

git clone https://github.com/SpiderLabs/ModSecurity-nginx

cd nginx-$nginx_version/

./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx
make modules

cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

cd /etc/nginx/

mkdir /etc/nginx/modsec
cd /etc/nginx/modsec
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
mv /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf.example /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf

cp /opt/ModSecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf

echo "Include /etc/nginx/modsec/modsecurity.conf" >> /etc/nginx/modsec/main.conf
echo "Include /etc/nginx/modsec/owasp-modsecurity-crs/crs-setup.conf" >> /etc/nginx/modsec/main.conf
echo "Include /etc/nginx/modsec/owasp-modsecurity-crs/rules/*.conf" >> /etc/nginx/modsec/main.conf

wget -P /etc/nginx/modsec/ https://github.com/SpiderLabs/ModSecurity/raw/v3/master/unicode.mapping
cd $jshielder_home

  clear
  f_banner 
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo -e "\e[93m[+]\e[00m Configuring ModSecurity for NginX"
  echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
  echo ""
  spinner
  cp templates/nginx /etc/nginx/nginx.conf
  cp templates/nginx_default /etc/nginx/conf.d/default.conf
  service nginx restart
  say_done

}

# Install, Configure and Optimize PHP for Nginx
install_secure_php82_nginx(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP 8 for NginX"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install -y software-properties-common
    add-apt-repository ppa:ondrej/php
    apt update
    apt install -y php8.2-fpm php8.2-common php8.2-mysql php8.2-xml php8.2-xmlrpc php8.2-curl php8.2-gd php8.2-imagick php8.2-cli php8.2-dev php8.2-imap php8.2-mbstring php8.2-opcache php8.2-soap php8.2-zip unzip -y
    apt install -y php8.2-cli php8.2-json php-pdo8.2 php8.2-pear php8.2-bcmath
    apt-get install -y php8.2-redis
    echo ""
    echo -n " Removing insecure configuration on php.ini..."
    spinner
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.2/fpm/php.ini; echo " OK"
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    service php8.2-fpm restart
    say_done
}


# Install, Configure and Optimize PHP for Nginx
install_secure_php8_nginx(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Installing, Configuring and Optimizing PHP 8 for NginX"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt install -y software-properties-common
    add-apt-repository ppa:ondrej/php
    apt update
    apt install -y php8.0-fpm php8.0-common php8.0-mysql php8.0-xml php8.0-xmlrpc php8.0-curl php8.0-gd php8.0-imagick php8.0-cli php8.0-dev php8.0-imap php8.0-mbstring php8.0-opcache php8.0-soap php8.0-zip unzip -y
    apt install -y php8.0-cli php8.0-json php-pdo8.0 php8.0-pear php8.0-bcmath
    apt-get install -y php8.0-redis
    echo ""
    echo -n " Removing insecure configuration on php.ini..."
    spinner
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/8.0/fpm/php.ini; echo " OK"
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    service php8.0-fpm restart
    say_done
}


install_redis(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install Redis"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    add-apt-repository -y ppa:chris-lea/redis-server
    apt-get update
    apt-get install -y redis-server
    say_done
    echo ""
    echo "Remember to set the bind 127.0.0.1 and internal IP of the machine"
}


install_supervisor(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install Supervisor"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install -y supervisor
    service supervisor restart
    systemctl enable supervisor
    nano /etc/supervisor/conf.d/laravel-app.conf
    cp templates/laravel-supervisor-horizon.conf /etc/supervisor/conf.d/laravel-supervisor-horizon.conf
    say_done
}


install_composer(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install Composer"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cd ~
    curl -s https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    say_done
}


install_node_npm(){
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install NPM and Node JS"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cd ~
    apt-get install -y build-essential
    curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&\
    sudo apt-get install -y nodejs
    nodejs -v
    npm -v
    say_done
}


install_mariadb_client()
{
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install MariaDB Client"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cd ~
    apt install -y software-properties-common
    apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
    sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.6/ubuntu focal main'
    apt update
    apt-get install -y mariadb-client
    say_done
}


install_mysql_client57()
{
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install MySql 5.7 Client"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    cd ~
    apt-get install -y mysql-client-core-5.7
    say_done
}


install_letsencrypt()
{
    clear
    f_banner
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo -e "\e[93m[+]\e[00m Install CERT bot"
    echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
    echo ""
    apt-get install -y software-properties-common
    add-apt-repository universe
    add-apt-repository ppa:certbot/certbot
    apt-get update
    apt-get install -y certbot python-certbot-nginx
    say_done
}

##################################################################################################################

clear
f_banner
echo -e "\e[34m-------------------------------------------------------------------\e[00m"
echo -e "\e[93m[+]\e[00m SELECT THE DESIRED OPTION"
echo -e "\e[34m-------------------------------------------------------------------\e[00m"
echo ""
echo "1. Install nginx, php, supervisor, composer"
echo "2. Install Mysql Server"
echo "22. Maria DB Client"
echo "3. Install Redis"
echo "4. Install supervisor"
echo "5. Install NGINX with mods"
echo "51. Add Nginx ensite"
echo "55. Install NGINX"
echo "6. Install PHP 8.2 for NGINX"
echo "65. Install PHP 8.0 for NGINX"
echo "61. Install PHP 7.4 for NGINX"
echo "7. Install Letsencrypt"
echo "8. Install MySql Client 5.7"
echo "9. Exit"
echo

read choice

case $choice in

1)
check_root
install_nginx
compile_modsec_nginx
install_secure_php_nginx
install_supervisor
install_composer
install_node_npm
;;

2)
check_root
install_secure_mysql
;;

2)
check_root
install_mariadb_client
;;

24)
check_root
install_secure_mysql
;;

26)
check_root
install_mariadb_client
;;

3)
check_root
install_redis
;;

4)
check_root
install_supervisor
;;

5)
check_root
install_nginx_with_mods
;;

51)
check_root
add_nginx_ensite
;;

55)
check_root
install_nginx
compile_modsec_nginx
;;

6)
check_root
install_secure_php82_nginx
;;

65)
check_root
install_secure_php8_nginx
;;

61)
check_root
install_secure_php_nginx
;;

7)
check_root
install_letsencrypt
;;

8)
check_root
install_mysql_client57
;;

9)
exit 0
;;

esac
##############################################################################################################