# Setting up Ubuntu (hardened), Deployer user plus PHP, Mysql, Nginx, Redis, Supervisor, Composer and NPM

There are three scripts, in that order

-  `secure-host.sh` which will configure and harden server
-  `php-mysql-nginx-redis-supervisor.sh` to install PHP 7.4, NGinX, Redis, Supervisor, as well as Composer and NPM/Node
-  `deployment-setup.sh` which will set up Deployer users

### Redis hardening

1.  Set up  /etc/redis/redis.conf to either `0.0.0.0` or trusted ip `127.0.0.1 10.0.0.1 10.0.0.2 10.0.0.3` etc
2.  Add a password to /etc/redis/redis.conf as `requirepass passwordidwhatever`

*Make sure you run `/etc/init.d/redis-server` restart after making the change.*
See: https://www.digitalocean.com/community/tutorials/how-to-secure-your-redis-installation-on-ubuntu-18-04

Error starting up: https://stackoverflow.com/questions/40317106/failed-to-start-redis-service-unit-redis-server-service-is-masked

https://www.initpals.com/redis/how-to-install-redis-in-ubuntu-with-ipv6-disabled/

https://stackoverflow.com/questions/36880321/why-redis-can-not-set-maximum-open-file



### MySQL
If the MYSQL is *different* from the webserver make sure you set `bind-address = 0.0.0.0` in  `/etc/mysql/my.cnf`


### Adding .htaccess for NGINX
See: https://www.digitalocean.com/community/tutorials/how-to-set-up-password-authentication-with-nginx-on-ubuntu-14-04


### IP Cheatsheet
See: https://www.andreafortuna.org/2019/05/08/iptables-a-simple-cheatsheet/


### Lets Encrypt
Certbot can be installed from `php-mysql-nginx-redis-supervisor.sh` 
Then checkout the document here: https://gist.github.com/mizansyed/1a65e8a91edfa42820de1225f519fe11

### Nginx
https://imstudio.medium.com/system-how-to-install-nginx-on-centos-7-x64-part-2-bd98ac6c1709

Remember:
Change the user/group to 'nginx' user in here (two places) `/etc/php/7.4/fpm/pool.d/www.conf` and restart php `sudo service php7.4-fpm restart`

user = nginx
group = nginx

listen.owner = www-data
listen.group = www-data

You need to add nginx and deployer to each other's group
`usermod -a -G nginx deployer`
`usermod -a -G deployer nginx`

You may need to add the following if you use deployer.php to `/etc/sudoers` to all deployer to restart php processes
`deployer ALL=(root) NOPASSWD: /bin/systemctl reload php8.0-fpm`
`deployer ALL=(root) NOPASSWD: /usr/sbin/service php8.0-fpm reload`

### Port Forwarding for Deployer

Read: https://docs.github.com/en/developers/overview/using-ssh-agent-forwarding
