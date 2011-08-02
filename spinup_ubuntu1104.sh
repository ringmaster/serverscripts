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

INSTALL_LOG=/var/log/spinup_ubuntu1010.log

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
	echo "(don't worry if there isn't much output, it's being logged here: $INSTALL_LOG)"
	sudo bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -q -y $packages >> $INSTALL_LOG"
}

# Make sure script is being run as root.
if [ `id -u` != 0 ]; then
	echo "You must execute this script as root!"
	exit 1
fi

# Add multiverse to the repository sources file.
cat >> /etc/apt/sources.list <<APT_SOURCES

# Multiverse repositories. !!Required for some server packages!! DO NOT REMOVE!!
deb http://us.archive.ubuntu.com/ubuntu/ natty multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ natty multiverse
deb http://us.archive.ubuntu.com/ubuntu/ natty-updates multiverse
deb-src http://us.archive.ubuntu.com/ubuntu/ natty-updates multiverse
APT_SOURCES

# Get new list of packages.
echo "Updating package lists..."
apt-get -q -y update >> $INSTALL_LOG

installnoninteractive "openssh-server mysql-server libapache2-mod-fastcgi apache2-mpm-worker php5-cgi php-pear php5-dev apache2-threaded-dev sqlite3 memcached curl php5-gd php5-mcrypt php5-memcache php5-mhash php5-curl php5-imap php5-ldap php5-mysql php5-sqlite php5-pspell php5-tidy php-apc subversion postfix git-core lrzsz"

cat > /etc/apache2/mods-available/fastcgi.conf <<FCGI_CONF
<IfModule mod_fastcgi.c>
 # Share a single PHP-managed fastcgi for all sites
 Alias /fcgi /var/local/fcgi
 # Prevent more than one instance of the fcgi wrapper
 FastCgiConfig -idle-timeout 20 -maxClassProcesses 1
 <Directory /var/local/fcgi>
   # Add use of CGI and symlinks
   Options +ExecCGI +FollowSymLinks
 </Directory>
 AddType application/x-httpd-php5 .php
 AddHandler fastcgi-script .fcgi
 Action application/x-httpd-php5 /fcgi/php-cgi-wrapper.fcgi
</IfModule>
FCGI_CONF

mkdir -p /var/local/fcgi/

cat > /var/local/fcgi/php-cgi-wrapper.fcgi <<FCGI_WRAPPER
#!/bin/sh
# Use the same settings used for mod_php.
# Change this if the php.ini is in /etc
PHPRC="/etc/php5/apache2"
export PHPRC

# Calculate the number of 100MB PHP procs that will fit in free memory
PHP_FCGI_CHILDREN=\`free -m | awk '/Mem:/ {printf "%d",$2 / 100}'\`
export PHP_FCGI_CHILDREN
exec /usr/bin/php-cgi
FCGI_WRAPPER

chmod -R 755 /var/local/fcgi

cat >> /etc/php5/conf.d/apc.ini <<APC_INI
apc.shm_size = 48
apc.include_once_override = 1
apc.mmap_file_mask = /tmp/apc.XXXXXX
APC_INI
 
a2enmod actions
/etc/init.d/apache2 restart

