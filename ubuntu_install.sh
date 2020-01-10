#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
        stty echo
		echo
		exit 1
}

trap catch_exits 1 2 3 15 20

catch_exits() {
		stty echo
		echo
        exit 1
}

echo "Enter new root password: "
stty -echo
read vpass
stty echo
echo

if [ "$vpass" = "" ] || [ "$vpass" = " " ]
then
  echo "Empty input!"
  exit 1
fi

echo "Enter IP address: "
read vip

if [ "$vip" = "" ] || [ "$vip" = " " ]
then
  echo "Empty input!"
  exit 1
fi

echo "Enter netmask: "
read vmask

if [ "$vmask" = "" ] || [ "$vmask" = " " ]
then
  echo "Empty input!"
  exit 1
fi

echo "Enter broadcast: "
read vbroadcast

if [ "$vbroadcast" = "" ] || [ "$vbroadcast" = " " ]
then
  echo "Empty input!"
  exit 1
fi

echo "Enter gateway: "
read vgateway 

if [ "$vgateway" = "" ] || [ "$vgateway" = " " ]
then
  echo "Empty input!"
  exit 1
fi

echo "root:$vpass" | chpasswd
sed -i '/#PermitRootLogin prohibit-password/c\PermitRootLogin yes' /etc/ssh/sshd_config
systemctl restart ssh

apt update
apt upgrade -y
apt install apt-transport-https -y
apt update
apt upgrade -y
apt install ifupdown -y
apt install qemu-guest-agent -y

rm /etc/network/interfaces

nic=`ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`
  
touch /etc/network/interfaces
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
echo "auto "$nic >> /etc/network/interfaces
echo "iface "$nic" inet static" >> /etc/network/interfaces
echo "address "$vip >> /etc/network/interfaces
echo "netmask "$vmask >> /etc/network/interfaces
echo "broadcast "$vbroadcast	>> /etc/network/interfaces
echo "gateway "$vgateway >> /etc/network/interfaces
echo "dns-nameservers "$vgateway >> /etc/network/interfaces

sed -i '/#DNS=/c\DNS='$vgateway'' /etc/systemd/resolved.conf

systemctl stop systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
systemctl disable systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
systemctl mask systemd-networkd.socket systemd-networkd networkd-dispatcher systemd-networkd-wait-online
apt --assume-yes purge nplan netplan.io
rm -rf /etc/netplan
apt autoremove -y
apt install -f -y

sed -i '/GRUB_CMDLINE_LINUX_DEFAULT="splash quiet"/c\GRUB_CMDLINE_LINUX_DEFAULT=""' /etc/default/grub
update-grub


shutdown -r now

