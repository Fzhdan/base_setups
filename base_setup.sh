#!/bin/bash

# visual text settings
RED="\e[31m"
GREEN="\e[32m"
GRAY="\e[37m"
YELLOW="\e[93m"

REDB="\e[41m"
GREENB="\e[42m"
GRAYB="\e[47m"
ENDCOLOR="\e[0m"

clear
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Base server config for Debian 12 11 and Fedora 38                          ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}This script installs an configure :                                        ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}password,ssh,fail2ban,rsyslog,firawalld,network,unattended-upgrades        ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Infos @ https://github.com/zzzkeil/base_setups                             ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR}            Version 2023.06.24 -  changelog on github                      ${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo ""
echo ""
echo ""
echo  -e "                    ${RED}To EXIT this script press any key${ENDCOLOR}"
echo ""
echo  -e "                            ${GREEN}Press [Y] to begin${ENDCOLOR}"
read -p "" -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

#
#root check
#
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${RED}Sorry, you need to run this as root${ENDCOLOR}"
	exit 1
fi

#
### check if Debian or Ubuntu
. /etc/os-release
if [[ "$ID" = 'debian' ]] || [[ "$ID" = 'ubuntu' ]]; then
   echo -e "OS ID check = ${GREEN}ok${ENDCOLOR}"
   else 
   echo -e "${RED}This script is only for Debian and Ubuntu ${ENDCOLOR}"
   exit 1
fi


if [[ "$VERSION_ID" = '11' ]] || [[ "$VERSION_ID" = '20.04' ]] || [[ "$VERSION_ID" = '22.04' ]]; then
   echo -e "OS Versions check = ${GREEN}ok${ENDCOLOR}"
   else
   echo -e "${RED}Only Debian 11 and Ubuntu 20.04 and 22.04 supported ${ENDCOLOR}"

   exit 1
fi



#
# OS updates
#
echo -e "${GREEN}update upgrade and install ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]] || [[ "$ID" = 'ubuntu' ]]; then
apt update && apt upgrade -y && apt autoremove -y
apt remove ufw -y
apt install firewalld fail2ban rsyslog unattended-upgrades apt-listchanges -y
fi



mkdir /root/script_backupfiles/
clear

#
# Password
#
echo -e " ${GREEN}Set a secure root password ${ENDCOLOR}"

echo ""
echo " This script can create a random secure root password."
echo ""
echo ""
echo  -e " ${GRAY}Press any key  -  to ${RED}NOT${ENDCOLOR} change root password ${ENDCOLOR}"
echo ""
echo  -e " ${GRAY}Press [C]  -  to create a secure random root password ${ENDCOLOR}"
read -p "" -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Cc]$ ]]
then
newpass=0
echo " Ok no password change"
echo " Get sure you use a secure password ! "
echo ""
echo ""
read -p "Press enter to continue"
else
newpass=1
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 64  ; echo)
echo "root:$randompasswd" | chpasswd
echo ""
echo ""
echo " Your new root password is : "
echo ""
echo -e "${GREEN}$randompasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e "${YELLOW} !!! Save this password now !!! ${ENDCOLOR}"
echo " Use your mouse to mark the green password (copy), and paste it on your secure location (other computer/passwordmanager/...) !"
echo ""
echo " if you not save this password, you can never loggin again, be carefull"
echo ""
echo ""
read -p "Press enter to continue"
echo ""
echo " just one more time. "
echo " if you not save this password, you can never loggin again, be carefull"
echo ""
echo ""
read -p "Press enter to continue"
clear
fi
clear

#
# SSH
#
echo -e "${GREEN}Set ssh config  ${ENDCOLOR}"

read -p "Choose your SSH Port: (default 22) " -e -i 2222 sshport
ssh-keygen -f /etc/ssh/key1rsa -t rsa -b 4096 -N ""
ssh-keygen -f /etc/ssh/key2ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key3ed25519 -t ed25519 -N ""

mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key1rsa
HostKey /etc/ssh/key2ecdsa
HostKey /etc/ssh/key3ed25519
macs hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
PermitRootLogin yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  internal-sftp" >> /etc/ssh/sshd_config
clear

#
# Network
#
echo -e "${GREEN}Set network config  ${ENDCOLOR}"

read -p "Your hostname :" -e -i remotehost hostnamex
hostnamectl set-hostname $hostnamex

if [ -f "/etc/network/interfaces.d/50-cloud-init.cfg" ]; then
   nano /etc/network/interfaces.d/50-cloud-init.cfg
fi

if [ -f "/etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection" ]; then
   nano /etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection
fi
clear

#
# firewalld
#
echo -e "${GREEN}Set firewalld config  ${ENDCOLOR}"

systemctl start firewalld
firewall-cmd --zone=public --add-port=$sshport/tcp
firewall-cmd --runtime-to-permanent
clear



#
# fail2ban
#
echo -e "${GREEN}Set fail2ban for ssh ${ENDCOLOR}"

echo "
[sshd]
enabled = true
port = $sshport
filter = sshd
logpath = /var/log/auth.log
backend = %(sshd_backend)s
maxretry = 3
banaction = firewallcmd-allports
findtime = 1d
bantime = 18w
" >> /etc/fail2ban/jail.d/ssh.conf
clear

#
# Updates
#
echo -e "${GREEN}unattended-upgrades  ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]]; then
mv /etc/apt/apt.conf.d/50unattended-upgrades /root/script_backupfiles/50unattended-upgrades.orig
echo 'Unattended-Upgrade::Origins-Pattern {
//      "origin=Debian,codename=${distro_codename}-updates";
//      "origin=Debian,codename=${distro_codename}-proposed-updates";
        "origin=Debian,codename=${distro_codename},label=Debian";
        "origin=Debian,codename=${distro_codename},label=Debian-Security";
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";

//      "o=Debian,a=stable";
//      "o=Debian,a=stable-updates";
//      "o=Debian,a=proposed-updates";
//      "o=Debian Backports,a=${distro_codename}-backports,l=Debian Backports";
};

Unattended-Upgrade::Package-Blacklist {

};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "01:30";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

echo '
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
' >> /etc/apt/apt.conf.d/20auto-upgrades

nano /etc/apt/apt.conf.d/50unattended-upgrades
nano /etc/apt/apt.conf.d/20auto-upgrades

sed -i "s@6,18:00@9,23:00@" /lib/systemd/system/apt-daily.timer
sed -i "s@12h@1h@" /lib/systemd/system/apt-daily.timer
sed -i "s@6:00@1:00@" /lib/systemd/system/apt-daily-upgrade.timer
clear
fi


if [[ "$systemos" = 'fedora' ]]; then
mv /etc/dnf/automatic.conf /root/script_backupfiles/automatic.conf.orig
echo '
[commands]
upgrade_type = default
# default or security

random_sleep = 0
network_online_timeout = 60
download_updates = yes
apply_updates = yes

reboot = when-needed
# never or when-changed or when-needed

reboot_command = "shutdown -r +5"

[emitters]
emit_via = stdio

[email]
#email_from = root@example.com
#email_to = root
#email_host = localhost

[command]

[command_email]
#email_from = root@example.com
#email_to = root

[base]
debuglevel = 1

' >> /etc/dnf/automatic.conf
nano /etc/dnf/automatic.conf
fi


#
#misc
#
echo -e "${GREEN}Clear/Change some stuff ${ENDCOLOR}"

if [[ "$systemos" = 'debian' ]]; then
echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
totalban1=$(zgrep 'Ban' /var/log/fail2ban.log* | wc -l)
echo "System uptime : $runtime1  / $runtime2 "
echo ""
echo "Test INFO (maybe wrong count)  -   Total banned IPs from fail2ban : $totalban1 "
' >> /etc/update-motd.d/99-base01
chmod +x /etc/update-motd.d/99-base01
fi

if [[ "$systemos" = 'fedora' ]]; then
echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
totalban1=$(zgrep 'Ban' /var/log/fail2ban.log* | wc -l)
echo "System uptime : $runtime1  / $runtime2 "
echo ""
echo "Test INFO (maybe wrong count)  -   Total banned IPs from fail2ban : $totalban1 "
'
>> /etc/profile.d/motd.sh
chmod +x /etc/profile.d/motd.sh
fi


echo "base_server script installed from :
https://github.com/zzzkeil/base_setups
" > /root/base_setup.README

#
# END
#
clear

echo ""
echo ""
if [[ "$newpass" -ne 0 ]]; then
echo -e " ${YELLOW}!!! REMEMBER - you set a new root password :"
echo  ""
echo -e "${GREEN}$randompasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e " ${RED}if you not save this password, you can never loggin again, be carefull ${ENDCOLOR}"
echo ""
echo ""
fi
echo ""
echo "Your settings:"
if [[ "$newpass" = '0' ]]; then
echo ""
echo "Your password has not changed "
fi
echo ""
echo "New ssh port = $sshport / and open in firewalld"
echo ""
echo ""
echo -e "${GREEN}Press enter to reboot  ${ENDCOLOR}"
echo ""
echo ""
read -p ""
systemctl enable fail2ban.service
systemctl enable firewalld
reboot
