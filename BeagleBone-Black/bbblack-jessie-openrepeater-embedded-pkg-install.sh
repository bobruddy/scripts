#!/bin/bash
(
###################################################################
#   Open Repeater Project
#
#    Copyright (C) <2015>  <Richard Neese> kb3vgw@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.
#
#    If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>
#
###################################################################
# Auto Install Configuration options 
# (set it, forget it, run it)
###################################################################

# ----- Start Edit Here ----- #
####################################################
# Repeater call sign
# Please change this to match the repeater call sign
####################################################
cs="Set-This"

###################################################
# Put /var/log into a tmpfs to improve performance 
# Super user option dont try this if you must keep 
# logs after every reboot
###################################################
put_logs_tmpfs="n"

# ----- Stop Edit Here ------- #
########################################################
# Set mp3/wav file upload/post size limit for php/nginx
# ( Must Have the M on the end )
########################################################
upload_size="25M"

#######################
# Nginx default www dir
#######################
WWW_PATH="/var/www"

#################################
#set Web User Interface Dir Name
#################################
gui_name="openrepeater"

#####################
#Php ini config file
#####################
php_ini="/etc/php5/fpm/php.ini"

######################################################################
# check to see that the configuration portion of the script was edited
######################################################################
if [[ $cs == "Set-This" ]]; then
  echo
  echo "Looks like you need to configure the scirpt before running"
  echo "Please configure the script and try again"
  exit 0
fi

##################################################################
# check to confirm running as root. # First, we need to be root...
##################################################################
if [ "$(id -u)" -ne "0" ]; then
  sudo -p "$(basename "$0") must be run as root, please enter your sudo password : " "$0" "$@"
  exit 0
fi
echo
echo "Looks Like you are root.... continuing!"
echo

###############################################
#if lsb_release is not installed it installs it
###############################################
if [ ! -s /usr/bin/lsb_release ]; then
	apt-get update && apt-get -y install lsb-release
fi

#################
# Os/Distro Check
#################
lsb_release -c |grep -i jessie &> /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo " OK you are running Debian 8 : Jessie "
else
	echo " This script was written for Debian 8 Jessie "
	echo
	echo " Your OS appears to be: " lsb_release -a
	echo
	echo " Your OS is not currently supported by this script ... "
	echo
	echo " Exiting the install. "
	exit
fi

###########################################
# Run a OS and Platform compatabilty Check
###########################################
########
# ARMEL
########
case $(uname -m) in armv[4-5]l)
echo
echo " ArmEL is currenty UnSupported "
echo
exit
esac

########
# ARMHF
########
case $(uname -m) in armv[6-9]l)
echo
echo " ArmHF arm v7 v8 v9 boards supported "
echo
esac

#############
# Intel/AMD
#############
case $(uname -m) in x86_64|i[4-6]86)
echo
echo " Intel / Amd boards currently Support is comming soon "
echo
exit
esac

###################
# Notes / Warnings
###################
echo
cat << DELIM
                   Not Ment For L.a.m.p Installs

                  L.A.M.P = Linux Apache Mysql PHP

                 THIS IS A ONE TIME INSTALL SCRIPT

             IT IS NOT INTENDED TO BE RUN MULTIPLE TIMES

         This Script Is Ment To Be Run On A Fresh Install Of

                         Debian 8 (Jessie)

     If It Fails For Any Reason Please Report To kb3vgw@gmail.com

   Please Include Any Screen Output You Can To Show Where It Fails
   
  Note:

  Pre-Install Information:

      This script uses Sqlite by default. No plans to use Other DB. 

DELIM

###############################################################################################
#Testing for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
###############################################################################################
echo
echo "This Script Currently Requires a internet connection "
echo
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	/bin/rm /tmp/index.google
	exit 1
else
	echo "I Found the Internet ... continuing!!!!!"
	/bin/rm /tmp/index.google
fi
echo
printf ' Current ip is : '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
echo

#####################################
# Reconfigure system for performance
#####################################
##############################
#Set a reboot if Kernel Panic
##############################
cat > /etc/sysctl.conf << DELIM
kernel.panic = 10
DELIM

####################################
# Set fs to run in a tempfs ramdrive
####################################
cat >> /etc/fstab << DELIM
tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/cache/apt/archives tmpfs   size=100M,defaults,noexec,nosuid,nodev,mode=0755 0 0
DELIM

# ####################################
# DISABLE BEAGLEBONE 101 WEB SERVICES
# ####################################
echo " Disabling The Beaglebone 101 web services "
systemctl disable cloud9.service
systemctl disable gateone.service
systemctl disable bonescript.service
systemctl disable bonescript.socket
systemctl disable bonescript-autorun.service
systemctl disable avahi-daemon.service
systemctl disable gdm.service
systemctl disable mpd.service

echo " Stoping The Beaglebone 101 web services "
systemctl stop cloud9.service
systemctl stop gateone.service
systemctl stop bonescript.service
systemctl stop bonescript.socket
systemctl stop bonescript-autorun.service
systemctl stop avahi-daemon.service
systemctl stop gdm.service
systemctl stop mpd.service

cat >> /boot/uEnv.txt << DELIM

#####################
#Disable HDMI sound
#####################
optargs=capemgr.disable_partno=BB-BONELT-HDMI
DELIM

apt-get -y autoremove apache2*

#############################
#Setting Host/Domain name
#############################
cat > /etc/hostname << DELIM
$cs-repeater
DELIM

#################
#Setup /etc/hosts
#################
cat > /etc/hosts << DELIM
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.0.1       $cs-repeater
DELIM

#################################################################################################
# Setting apt_get to use the httpredirecter to get
# To have <APT> automatically select a mirror close to you, use the Geo-ip redirector in your
# sources.list "deb http://httpredir.debian.org/debian/ jessie main".
# See http://httpredir.debian.org/ for more information.  The redirector uses HTTP 302 redirects
# not dnS to serve content so is safe to use with Google dnS.
# See also <which httpredir.debian.org>.  This service is identical to http.debian.net.
#################################################################################################
cat > "/etc/apt/sources.list" << DELIM
deb http://httpredir.debian.org/debian/ jessie main contrib non-free
deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free
deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free

DELIM

##########################
# Adding bbblack Repo
##########################
cat >> "/etc/apt/sources.list.d/beaglebone.list" << DELIM
deb [arch=armhf] http://repos.rcn-ee.net/debian/ jessie main
DELIM

#########################
# SVXLink Testing repo
#########################
cat > "/etc/apt/sources.list.d/svxlink.list" <<DELIM
deb http://repo.openrepeater.com/svxlink/release/debian/ jessie main
DELIM

##########################
# Adding OpenRepeater Repo
##########################
cat > "/etc/apt/sources.list.d/openrepeater.list" <<DELIM
deb http://repo.openrepeater.com/openrepeater/release/debian/ jessie main
DELIM

######################
#Update base os
######################
for i in update upgrade ;do apt-get -y "${i}" ; done

######################
#Install Dependancies
#####################
apt-get install -y --force-yes memcached sqlite3 libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 \
		ntp libasound2 libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 alsa-base bzip2 sudo gpsd gpsd-clients \
		flite wvdial screen time uuid inetutils-syslogd vim install-info usbutils whiptail dialog logrotate cron \
		gawk watchdog python3-serial

#####################
# Install SvxLink
#####################
apt-get install -y --force-yes svxlink-server remotetrx 

###########
# Clean Up
###########
apt-get clean

if [[ $raspbian_os_img == "n" ]]; then
apt-get install -y network-manager tcpd python-pysqlite2 
fi
rm /var/cache/apt/archive/*

#Working on sounds pkgs for future release of svxlink
cd /usr/share/svxlink/sounds
wget https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/14.08/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
tar xjvf svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
mv en_US-heather* en_US
rm svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
cd /root

##########################################
#---Start of nginx / php5 install --------
##########################################
apt-get -y install ssl-cert nginx php5-cli php5-common php-apc php5-gd php-db php5-fpm php5-memcache php5-sqlite

###########
# Clean Up
###########
apt-get clean

##################################################
# Changing file upload size from 2M to upload_size
##################################################
sed -i "$php_ini" -e "s#upload_max_filesize = 2M#upload_max_filesize = $upload_size#"

######################################################
# Changing post_max_size limit from 8M to upload_size
######################################################
sed -i "$php_ini" -e "s#post_max_size = 8M#post_max_size = $upload_size#"

#####################################################################################################
#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
#####################################################################################################
cat > "/etc/nginx/sites-available/$gui_name"  << DELIM
server{
        listen 127.0.0.1:80;
        server_name 127.0.0.1;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        client_max_body_size 25M;
        client_body_buffer_size 128k;

        root /var/www/openrepeater;
        index index.php;

        location ~ \.php$ {
           include snippets/fastcgi-php.conf;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
              deny all;
        }
        location ~ .htpassword {
              deny all;
        }
        location ~^.+.(db)$ {
              deny all;
        }
} 
server{
        listen 443;
        listen [::]:443 default_server ipv6only=on;

        include snippets/snakeoil.conf;
        ssl  on;

        root /var/www/openrepeater;

        index index.php;

        server_name $gui_name;

        location / {
            try_files \$uri \$uri/ =404;
        }

        client_max_body_size 25M;
        client_body_buffer_size 128k;
        
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_param   SCRIPT_FILENAME /var/www/openrepeater/\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}

DELIM

###############################################
# set nginx worker level limit for performance
###############################################
cat > "/etc/nginx/nginx.conf"  << DELIM
user www-data;
worker_processes 4;
pid /run/nginx.pid;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	open_file_cache max=1000 inactive=20s;
	open_file_cache_valid 30s;
	open_file_cache_min_uses 2;
	open_file_cache_errors off;

	fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=microcache:15M max_size=1000m inactive=60m;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;
	gzip_static on;
	gzip_disable "msie6";

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}

DELIM

#################################
# Backup and replace www.conf
#################################
cp /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig

cat >  /etc/php5/fpm/pool.d/www.conf << DELIM
[www]

user = www-data
group = www-data

listen = /var/run/php5-fpm.sock

listen.owner = www-data
listen.group = www-data

pm = static

pm.max_children = 5

pm.start_servers = 2

pm.max_requests = 100

chdir = /
DELIM

#################################
# Backup and replace php5-fpm.conf
#################################
cp /etc/php5/fpm/php-fpm.conf /etc/php5/fpm/php-fpm.conf.orig

cat > /etc/php5/fpm/php-fpm.conf << DELIM
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;include=/etc/php5/fpm/*.conf

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]

pid = /run/php5-fpm.pid

; Error log file
error_log = /var/log/php5-fpm.log

; syslog_facility is used to specify what type of program is logging the
; message. This lets syslogd specify that messages from different facilities
; will be handled differently.
; See syslog(3) for possible values (ex daemon equiv LOG_DAEMON)
; Default Value: daemon
;syslog.facility = daemon

syslog.ident = php-fpm

emergency_restart_threshold = 10

emergency_restart_interval = 1m

process_control_timeout = 10

process.max = 12

systemd_interval = 60

include=/etc/php5/fpm/pool.d/*.conf
DELIM

##############################################################
# linking openrepeater nginx config from avaible to enabled sites
##############################################################
ln -s /etc/nginx/sites-available/"$gui_name" /etc/nginx/sites-enabled/"$gui_name"

######################
#disable default site
######################
rm -rf /etc/nginx/sites-enabled/default

# Make sure the path /var/www/ is owned by your web server user:
chown -R www-data:www-data /var/www

##############################
#Restarting Nginx and PHP FPM
##############################
for i in nginx php5-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done

#################################################
# Fetch and Install open repeater project web ui
# ################################################
mkdir $WWW_PATH/$gui_name

apt-get install -y --force-yes openrepeater

find "$WWW_PATH" -type d -exec chmod 775 {} +
find "$WWW_PATH" -type f -exec chmod 664 {} +

chown -R www-data:www-data $WWW_PATH

cp /etc/default/svxlink /etc/default/svxlink.orig
cat > "/etc/default/svxlink" << DELIM
#############################################################################
#
# Configuration file for the SvxLink startup script /etc/init.d/svxlink
#
#############################################################################

# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/svxlink.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

#uesd for openrepeater to get gpio pins
if [ -r /etc/openrepeater/svxlink/svxlink_gpio.conf ]; then
        . /etc/openrepeater/svxlink/svxlink_gpio.conf
fi

DELIM

mv /etc/default/remotetrx /etc/default/remotetrx.orig
cat > "/etc/default/remotetrx" << DELIM
#############################################################################
#
# Configuration file for the RemoteTrx startup script /etc/init.d/remotetrx
#
#############################################################################

# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/remotetrx.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

DELIM

#############################################
#making links to make svxlink work correctly
#############################################
ln -s /usr/share/openrepeater/sounds /var/www/openrepeater/sounds
ln -s /etc/openrepeater/svxlink/local-events.d/ /usr/share/svxlink/events.d/local
ln -s /var/log/svxlink /var/www/openrepeater/log

chown www-data:www-data /var/www/openrepeater/sounds
chown -R www-data:www-data /var/lib/openrepeater /etc/openrepeater

#########################
#restart svxlink service
#########################
service svxlink restart

cat >> /etc/sudoers << DELIM
#allow www-data to access amixer and service
www-data   ALL=(ALL) NOPASSWD: /usr/bin/openrepeater_svxlink_restart, NOPASSWD: /usr/bin/openrepeater_svxlink_start, NOPASSWD: /usr/bin/openrepeater_svxlink_stop, NOPASSWD: /usr/bin/aplay, NOPASSWD: /usr/bin/arecord
DELIM

echo " ########################################################################################## "
echo " #            You will need to edit the php.ini file and add extensions=memcache.so       # " 
echo " #               location : /etc/php5/fpm/php.ini and then restart web service            # "
echo " ########################################################################################## "
echo
echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " #                                                                                        # "
echo " #                   To Start the service fo svxlink on the cmd line                      # "
echo " #                        run cmd: systemctl enable svxlink.service                       # "
echo " #                                                                                        # "
echo " #                   To Start the service fo remotetrx on the cmd line                    # "
echo " #                        run cmd: systemctl enable remotetrx.service                     # "
echo " #                                                                                        # "
echo " ########################################################################################## "
) | tee /root/install.log