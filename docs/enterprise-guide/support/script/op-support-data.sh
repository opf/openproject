#!/bin/bash

#Scope is to discover the user's environment for a future or existing OpenProject Enterprise on-premises packaged installation running on Linux

#VERBOSE LOGGING
#set -x

#PSQL
read -p "Please specify the IP of the PSQL server, if the internal PSQL server of OpenProject is used press ENTER [127.0.0.1]: " psqlserver
psqlserver=${psqlserver:-127.0.0.1}
read -p "Please specify the PORT of the PSQL server, if the internal PSQL server of OpenProject is used press ENTER [45432]: " psqlserverport
psqlserverport=${psqlserverport:-45432}

#OWN WEB SERVER
echo
read -p "Please specify if your own web server is used for terminating SSL, if the internal webserver of OpenProject is used press ENTER [N,y]: " ownwebserver
ownwebserver=${ownwebserver:-N}

if [ "$ownwebserver" != "${ownwebserver#[Yy]}" ]; then
  read -p "Please name the webserver application that you use [apache]: "
  webserverapp=${webserverapp:-apache}
else
  webserverapp="internal"
fi
# LETSENCRYPT!
read -p "Enter SSL Certificate (incl. full path) [/etc/ssl/certs/ssl-cert-snakeoil.pem]: " ssl_certificate
ssl_certificate=${ssl_certificate:-/etc/ssl/certs/ssl-cert-snakeoil.pem}
read -p "Enter SSL Key (incl. full path) [/etc/ssl/private/ssl-cert-snakeoil.key]: " ssl_key
ssl_key=${ssl_key:-/etc/ssl/private/ssl-cert-snakeoil.key}

ssoserver="local-auth"
#SSO SOLUTION
echo
read -p "Please specify if there is an SSO solution like SAML/LDAP/OpenID for authenticating in OpenProject [N,y]: " ssosolution
ssosolution=${ssosolution:-N}
if [ "$ssosolution" != "${ssosolution#[Yy]}" ]; then
  echo
  echo As OpenProject will connect to the SSO host we need some details to be provided:
  read -p "Enter SSO host IP [127.0.0.1]: " ssoserver
  ssoserver=${ssoserver:-127.0.0.1}
  read -p "Enter SSO host Port [443]: " ssoport
  ssoport=${ssoport:-443}
fi

#OUTGOING MAILS
echo
read -p "Please specify if outgoing e-mails are used (SMTP) [Y,n]: " outgoingmail
outgoingmail=${outgoingmail:-Y}
if [ "$outgoingmail" != "${outgoingmail#[Yy]}" ]; then
  echo
  echo As OpenProject will send e-mails we need some details to be provided:
  read -p "Enter SMTP host IP [127.0.0.1]: " outgoingmailip
  outgoingmailip=${outgoingmailip:-127.0.0.1}
  read -p "Enter SMTP host Port [25]: " outgoingmailport
  outgoingmailport=${outgoingmailport:-25}
fi

#INCOMING MAILS
echo
read -p "Please specify if incoming e-mails are used (IMAP/POP3) [Y,n]: " incomingmail
incomingmail=${incomingmail:-Y}
if [ "$incomingmail" != "${incomingmail#[Yy]}" ]; then
  echo
  echo As OpenProject shall receive e-mails we need some details to be provided:
  read -p "Enter IMAP/POP3 host IP [127.0.0.1]: " incomingmailip
  incomingmailip=${incomingmailip:-127.0.0.1}
  read -p "Enter IMAP/POP3 host Port [110]: " incomingmailport
  incomingmailport=${incomingmailport:-110}
fi

#S3 CLOUD STORAGE
echo
read -p "Please specify if S3 cloud storage is used [N,y]: " s3cloudstorage
s3cloudstorage=${s3cloudstorage:-N}

#DOMAIN NAME
echo
echo 'Please specify the fully qualified domain (FQDN) name for your OpenProject installation.'
read -p "Answer (e.g. openproject.company.com): " fqdn


#CHECK LINUX INFORMATION ON LOCALHOST
echo Linux Information on localhost
ls -la /etc/*-release
ls -la /etc/issue*
echo "---"
cat /etc/*-release
echo "---"
cat /etc/issue*
echo "---"
cat /proc/version
echo "---"
uname -a
echo "---"
cat /etc/[A-Za-z]*[_-][rv]e[lr]*
echo "---"

#CHECK FILESYSTEMS ON LOCALHOST
echo Filesystems on localhost
cat /etc/fstab | grep -vE "^#"
echo "---"
df -h
echo "---"

#CHECK LOCALHOST IPS
echo Network on localhost
ip a
echo "---"

#CHECK LOCAL MEMCACHED CONFIG
echo
echo Search for memcached

hash memcached 2>/dev/null
if [ $? == 1 ]; then
  echo "memcached is NOT installed"
else
  echo "memcached is installed"
fi
echo "---"

#CHECK DOCKER ENVIRONMENT
hash docker 2>/dev/null
if [ $? == 1 ]; then
  echo
  echo "Docker is not installed yet, if you consider using the OpenProject containers, please install docker."
else
  docker ps -a
  docker volume ls
fi

#SSL/TLS CERTS AVAILABLE
if [ "$ownwebserver" != "${ownwebserver#[Nn]}" ]; then
  echo Search for SSL certificate $ssl_certificate
  find $ssl_certificate
  echo Search for SSL key $ssl_key
  find $ssl_key
  openssl x509 -in $ssl_certificate -noout -text
  openssl rsa -in $ssl_key -noout -text
  openssl x509 -noout -modulus -in $ssl_certificate | openssl md5
  openssl rsa -noout -modulus -in $ssl_key | openssl md5
fi
echo
echo
echo "========="
echo " SUMMARY "
echo "========="
echo
#CHECK WEBSERVER ON LOCALHOST PORTS 80 AND 443
echo 'Checking Port 80,443 on IP 127.0.0.1 reachable? (0=YES / 1=NO)'
echo 2>/dev/null > /dev/tcp/127.0.0.1/80 ; echo $?
echo 2>/dev/null > /dev/tcp/127.0.0.1/443 ; echo $?
echo "---"

#CHECK WEBSERVER ON OTHER IPS
for ip in `ip a | grep "inet " | grep " e" | awk -F" " '{print $2}' | cut -d'/' -f1`; do
echo 'Checking Port 80,443 on IP '$ip' reachable? (0=YES / 1=NO)'
echo 2>/dev/null > /dev/tcp/$ip/80 ; echo $?
echo 2>/dev/null > /dev/tcp/$ip/80 ; echo $?
done
echo "---"

#CHECK packager.io ACCESS FROM LOCALHOST FOR UPGRADES
echo 'packager.io web server is reachable on ports 80,443? (0=YES / 1=NO)'
packagerip=`host -t a packager.io | cut -d" " -f4`
echo 2>/dev/null > /dev/tcp/$packagerip/80 ; echo $?
echo 2>/dev/null > /dev/tcp/$packagerip/443 ; echo $?
echo "---"

#CHECK PSQL REACHABILITY
echo 'PSQL server on IP/FQDN '$psqlserver' port '$psqlserverport' reachable (0=YES / 1=NO)'
echo 2>/dev/null > /dev/tcp/$psqlserver/$psqlserverport ; echo $?
echo "---"

#CHECK SSO REACHABILITY
if [ "$ssosolution" != "${ssosolution#[Yy]}" ]; then
  echo 'SSO server on IP/FQDN '$ssoserver' port '$ssoport' reachable? (0=YES / 1=NO)'
  echo 2>/dev/null > /dev/tcp/$ssoserver/$ssoserverport ; echo $?
  echo "---"
fi

#CHECK SMTP REACHABILITY
if [ "$outgoingmail" != "${outgoingmail#[Yy]}" ]; then
  echo 'SMTP server on IP/FQDN '$outgoingmailip' port '$outgoingmailport' reachable? (0=YES / 1=NO)'
  echo 2>/dev/null > /dev/tcp/$outgoingmailip/$outgoingmailport ; echo $?
  echo "---"
fi

#CHECK POP3/IMAP REACHABILITY
if [ "$incomingmail" != "${incomingmail#[Yy]}" ]; then
  echo 'POP3/IMAP server on IP/FQDN '$incomingmailip' port '$incomingmailport' reachable? (0=YES / 1=NO)'
  echo 2>/dev/null > /dev/tcp/$incomingmailip/$incomingmailport ; echo $?
  echo "---"
fi


echo "---"
echo User Input:
echo PSQL: $psqlserver":"$psqlserverport
echo SSL: $ssl_certificate", "$ssl_key
echo Own Web Server: $ownwebserver
echo Web Server Application: $webserverapp
echo SSO Server: $ssoserver":"$ssoport
echo SMTP Server: $outgoingmailip":"$outgoingmailport
echo IMAP/POP3 Server: $incomingmailip":"$incomingmailport
echo S3 Cloud Storage: $s3cloudstorage
echo FQDN: $fqdn
echo "---"


#CHECK FOR INSTALLED OPENPROJECT

echo "Checking for OpenProject installed packages and version..."

yum_fp=`which yum` 
if [ -z $yum_fp ]; then yum_fp="dummynonexists"; fi
if [ -f $yum_fp ]; then $yum_fp list --installed | grep openproject; fi
apt_fp=`which apt`
if [ -z $apt_fp ]; then apt_fp="dummynonexists"; fi
if [ -f $apt_fp ]; then $apt_fp list --installed | grep openproject; fi
openproject_fp=`which openproject`
if [ -z $openproject_fp ]; then openproject_fp="dummynonexists"; fi 
if [ -f $openproject_fp ];
  then echo OpenProject is installed in Version...; $openproject_fp run bundle exec rake version
else
  echo "OpenProject seems not to be installed."
fi

