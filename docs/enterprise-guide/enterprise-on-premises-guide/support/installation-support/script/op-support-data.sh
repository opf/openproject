#!/bin/bash

#Scope is to discover the user's environment for a future or existing OpenProject Enterprise on-premises packaged installation running on Linux

#VERBOSE LOGGING
#set -x

hash netcat 2>/dev/null
if [ $? == 1 ]; then
  echo
  echo "Please install netcat (apt install netcat, yum install netcat) as this script depends on netcat. Thank you."
  exit
fi 

#PSQL
read -p "Please specify the IP/FQDN of the PSQL server, if the internal PSQL server of OpenProject is used press ENTER [127.0.0.1]: " psqlserver
psqlserver=${psqlserver:-127.0.0.1}
read -p "Please specify the PORT of the PSQL server, if the internal PSQL server of OpenProject is used press ENTER [45432]: " psqlserverport
psqlserverport=${psqlserverport:-45432}

#OWN WEB SERVER
echo
read -p "Please specify if your own web server is used for terminating SSL, if the internal webserver of OpenProject is used press ENTER [N,y]: " ownwebserver
ownwebserver=${ownwebserver:-N}

if [ "$ownwebserver" != "${ownwebserver#[Nn]}" ]; then
  echo 
  echo As OpenProject will configure the webserver, SSL certificate and key need to be provided:
# LETSENCRYPT!
  read -p "Enter SSL Certificate (incl. full path) [/etc/ssl/certs/ssl-cert-snakeoil.pem]: " ssl_certificate
  ssl_certificate=${ssl_certificate:-/etc/ssl/certs/ssl-cert-snakeoil.pem}
  read -p "Enter SSL Key (incl. full path) [/etc/ssl/private/ssl-cert-snakeoil.key]: " ssl_key
  ssl_key=${ssl_key:-/etc/ssl/private/ssl-cert-snakeoil.key}
fi

#SSO SOLUTION
echo
read -p "Please specify if there is an SSO solution like SAML/LDAP/OpenID for authenticating in OpenProject [N,y]: " ssosolution
ssosolution=${ssosolution:-N}
if [ "$ssosolution" != "${ssosolution#[Yy]}" ]; then
  echo
  echo As OpenProject will connect to the SSO host we need some details to be provided:
  read -p "Enter SSO host IP/FQDN: " ssoserver
  read -p "Enter SSO host Port: " ssoport
fi

#OUTGOING MAILS
echo
read -p "Please specify if outgoing e-mails are used (SMTP) [Y,n]: " outgoingmail
outgoingmail=${outgoingmail:-Y}
if [ "$outgoingmail" != "${outgoingmail#[Yy]}" ]; then
  echo
  echo As OpenProject will send e-mails we need some details to be provided:
  read -p "Enter SMTP host IP/FQDN: " outgoingmailip
  read -p "Enter SMTP host Port: " outgoingmailport
fi

#INCOMING MAILS
echo
read -p "Please specify if incoming e-mails are used (IMAP/POP3) [Y,n]: " incomingmail
incomingmail=${incomingmail:-Y}
if [ "$incomingmail" != "${incomingmail#[Yy]}" ]; then
  echo
  echo As OpenProject shall receive e-mails we need some details to be provided:
  read -p "Enter IMAP/POP3 host IP/FQDN: " incomingmailip
  read -p "Enter IMAP/POP3 host Port: " incomingmailport
fi

#S3 CLOUD STORAGE
echo
read -p "Please specify if S3 cloud storage is used [N,y]: " s3cloudstorage
s3cloudstorage=${s3cloudstorage:-N}

#DOMAIN NAME
echo
echo 'Please specify the fully qualified domain (FQDN) name for your OpenProject installation.'
read -p "Answer (e.g. openproject.company.com): " fqdn

echo "---"
echo User Input:
echo PSQL: $psqlserver":"$psqlserverport
echo SSL: $ssl_certificate", "$ssl_key
echo Own Web Server: $ownwebserver
echo SSO Server: $ssoserver":"$ssoport
echo SMTP Server: $outgoingmailip":"$outgoingmailport
echo IMAP/POP3 Server: $incomingmailip":"$incomingmailport
echo S3 Cloud Storage: $s3cloudstorage
echo FQDN: $fqdn
echo "---"

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
echo Filesystems on locahost
cat /etc/fstab | grep -vE "^#"
echo "---"
df -h
echo "---"

#CHECK LOCALHOST IPS
echo Network on localhost
ip a
echo "---"


#CHECK WEBSERVER ON LOCALHOST PORTS 80 AND 443
echo 'Checking Port 80,443 on IP 127.0.0.1 reachable? (succeeded = reachable)'
netcat -z -v 127.0.0.1 80 2>&1
netcat -z -v 127.0.0.1 443 2>&1
echo "---"

#CHECK WEBSERVER ON OTHER IPS
for ip in `ip a | grep "inet " | grep " e" | awk -F" " '{print $2}' | cut -d'/' -f1`; do
echo 'Checking Port 80,443 on IP '$ip' reachable? (succeeded = reachable)'
netcat -z -v $ip 80 2>&1
netcat -z -v $ip 443 2>&1
done
echo "---"

#CHECK packager.io ACCESS FROM LOCALHOST FOR UPGRADES
echo packager.io web server is reachable on ports 80,443
netcat -z -v packager.io 80 2>&1
netcat -z -v packager.io 443 2>&1
echo "---"

#CHECK PSQL REACHABILITY
echo 'PSQL server on IP/FQDN '$psqlserver' port '$psqlserverport' reachable (0=YES / 1=NO)'
echo 'SELECT version();QUIT' | netcat $psqlserver $psqlserverport; echo $?
echo "---"

#CHECK SSO REACHABILITY
if [ "$ssosolution" != "${ssosolution#[Yy]}" ]; then
  echo 'SSO server on IP/FQDN '$ssoserver' port '$ssoport' reachable? (succeeded = reachable)'
  netcat -z -v $ssoserver $ssoport 2>&1
  echo "---"
fi

#CHECK SMTP REACHABILITY
if [ "$outgoingmail" != "${outgoingmail#[Yy]}" ]; then
  echo 'SMTP server on IP/FQDN '$outgoingmailip' port '$outgoingmailport' reachable? (succeeded = reachable)'
  netcat -z -v $outgoingmailip $outgoingmailport 2>&1
  echo "---"
fi

#CHECK POP3/IMAP REACHABILITY
if [ "$incomingmail" != "${incomingmail#[Yy]}" ]; then
  echo 'POP3/IMAP server on IP/FQDN '$incomingmailip' port '$incomingmailport' reachable? (succeeded = reachable)'
  netcat -z -v $incomingmailip $incomingmailport 2>&1
  echo "---"
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

#CHECK FOR INSTALLED OPENPROJECT

echo "Checking for Open Project installed packages and version..."

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
  echo "Open Project seems not to be installed."
fi

