#!/bin/bash

echo "Enter domain name:"
read DOMAIN
DOMAINUPPER=${DOMAIN^^}
WORKGROUP=$(echo $DOMAINUPPER | sed 's/.LOCAL//')
IP=$(ip a list dev eth0| grep "inet\s" |  awk '{print $2 }'  | sed 's/\/24//')
HOSTNAME=$(hostname)
echo "Enter domain controller IP:"
read DOMAINIP

#apt-get update
#apt install krb5-user samba sssd ntp

cat smb | sed "s/QW.LOCAL/$DOMAINUPPER/" > smb.conf
cat smb | sed "s/QW/$WORKGROUP/" > smb.conf
cat krb5 | sed "s/QW.LOCAL/$DOMAINUPPER/" > krb5.conf
cat sssd | sed "s/qw.local/$DOMAIN/" > sssd.conf
echo "127.0.0.1 localhost" > hosts
echo "$IP $HOSTNAME.$DOMAIN $HOSTNAME" >> hosts

cp /etc/network/interfaces interfaces.org
cat interfaces.org | sed "s/dns-nameserver.*/dns-nameserver $DOMAINIP/" | sed "s/dns-search.*//"  > interfaces
echo "    dns-search $DOMAIN" >> interfaces
systemctl networking restart

cp /etc/krb5.conf /etc/krb5.conf.old
cp /etc/samba/smb.conf /etc/samba/smb.conf.old
cp  /etc/sssd/sssd.conf  /etc/sssd/sssd.conf.old
cp ./krb5.conf /etc/krb5.conf
cp ./smb.conf /etc/samba/smb.conf
cp ./sssd.conf /etc/sssd/sssd.conf
cp ./hosts /etc/hosts

echo "kerberos ticket authentication:"
kinit administrator
echo "Join domain $DOMAIN:"
net ads join -U administrator
rm ./*.conf
rm ./interfaces*
rm hosts

