#!/bin/bash

# This script is meant to configure a stack on Ubuntu 11.04
# It installs Apache mpm-worker, a threaded version of Apache that is faster 
# than mpm-prefork, especially for serving small files.
# It also installs PHP as FastCGI, which is better for a couple of reasons:
# * FastCGI processes stay in memory to serve multiple requests.
# * FastCGI is separate form Apache, so Apache doesn't need to load all of PHP 
#     in order to serve static files, as it does with mod_php
# PHP is installed with gd, mcrypt, mhash, imap, ldap, pdo, mysql, sqlite,
# memcache, curl, pspell, tidy
# PEAR is installed and APC is enabled
# memcached is installed

INSTALL_LOG=/var/log/spinup_ubuntu1204.log

# Make sure we didn't already run this script. Probably wouldn't /really/ hurt,
# but just to be careful...
if [ -e $INSTALL_LOG ]; then
	echo "You have already run this script. Doing so again might make things weird."
	exit 2;
fi

touch $INSTALL_LOG

function installnoninteractive() {
	local packages="$1"
	echo "Installing: $packages"
	sudo bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -q -y $packages >> $INSTALL_LOG"
}

# Make sure script is being run as root.
if [ `id -u` != 0 ]; then
	echo "You must execute this script as root!"
	exit 1
fi

echo "Don't worry if there isn't much output, it's being logged here: $INSTALL_LOG"

installnoninteractive "python-software-properties python g++ make"

add-apt-repository -y 'deb http://us.archive.ubuntu.com/ubuntu/ precise multiverse'
add-apt-repository -y 'deb-src http://us.archive.ubuntu.com/ubuntu/ precise multiverse'
add-apt-repository -y 'deb http://us.archive.ubuntu.com/ubuntu/ precise-updates multiverse'
add-apt-repository -y 'deb-src http://us.archive.ubuntu.com/ubuntu/ precise-updates multiverse'

# Get new list of packages.
echo "Updating package lists..."
apt-get -q -y update >> $INSTALL_LOG

# Add multiverse to the repository sources file.
#cat >> /etc/apt/sources.list <<APT_SOURCES

# Multiverse repositories. !!Required for some server packages!! DO NOT REMOVE!!
# deb http://us.archive.ubuntu.com/ubuntu/ precise multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ precise multiverse
# deb http://us.archive.ubuntu.com/ubuntu/ precise-updates multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ precise-updates multiverse
# APT_SOURCES

installnoninteractive "openssh-server mysql-server nginx php5-cgi php5-fpm php-pear php5-dev sqlite3 memcached curl php5-gd php5-mcrypt php5-memcache php5-mhash php5-curl php5-imap php5-ldap php5-mysql php5-sqlite php5-pspell php5-tidy php-apc postfix git-core lrzsz zsh tmux vim python2.7-doc binutils binfmt-support ctags vim-doc vim-scripts indent"

add-apt-repository -q -y ppa:chris-lea/node.js >> $INSTALL_LOG
apt-get -q -y update >> $INSTALL_LOG
installnoninteractive "nodejs"

adduser --system --no-create-home nginx

cat > /etc/nginx/nginx.conf <<NGINX_CONF
user nginx www-data;
worker_processes 4;
pid /var/run/nginx.pid;

events {
	worker_connections 768;
	# multi_accept on;
}

http {
# Basic Settings
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

# Logging Settings
log_format gzip '$remote_addr - $remote_user [$time_local]  '
                '"$request" $status $bytes_sent '
                '"$http_referer" "$http_user_agent" "$gzip_ratio"';

	access_log /var/log/nginx/access.log gzip buffer=32k;
	error_log /var/log/nginx/error.log notice;

# Gzip Settings
	gzip on;
	gzip_disable "msie6";

	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

# Virtual Host Configs
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;

}
NGINX_CONF

mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled

cat > /etc/nginx/fastcgi_params <<FCGI_PARAMS
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;

fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param   SCRIPT_FILENAME 	\$document_root$fastcgi_script_name;
fastcgi_param   PATH_INFO 		\$fastcgi_script_name;

fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;

fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param	REDIRECT_STATUS		200;
FCGI_PARAMS

cat >> /etc/nginx/sites-available/VDR <<VDR
server {
    server_name  ~^www\.(?P<wwwdomain>.*)$;
    rewrite ^(.*) http://\$wwwdomain\$1 permanent;
}

server {
        listen 80;
        server_name ~^(?P<domain>.+)\$;
        root   /var/www/\$domain/htdocs;
        index index.php;
	# include /etc/nginx/security;

	# Logging --
	access_log  /var/log/nginx/\$domain.access.log;
	error_log  /var/log/nginx/\$domain.error.log notice;

        # serve static files directly
        location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
            access_log        off;
            expires           max;
        }
 
        location ~ \.php$ {
		try_files \$uri =404;
                # fastcgi_pass unix:/var/run/php5-fpm/\$domain.socket;
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                include /etc/nginx/fastcgi_params;
        }
}
VDR

ln -s /etc/nginx/sites-available/VDR /etc/nginx/sites-enabled/VDR

cat >> /etc/php5/conf.d/apc.ini <<APC_INI
apc.shm_size = 48
apc.include_once_override = 1
apc.mmap_file_mask = /tmp/apc.XXXXXX
APC_INI
 
/etc/init.d/php5-fpm start
/etc/init.d/nginx start
