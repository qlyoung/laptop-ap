#!/bin/bash
#
# sets up wireless access point on wlp3s0
# internet-connected interface is enp0s25
#
# Author: Quentin Young

# root check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# disable networkmanager for wifi
# this will soft-block the wifi interface with rfkill as a side effect
nmcli radio wifi off

# unblock wifi interface with rfkill
rfkill unblock wifi

# give wlp3s0 (the ap interface) an ip and netmask
ip addr add 192.168.8.1/24 dev wlp3s0

# kill dnsmasq (networkmanager runs it by default)
killall dnsmasq

# start dnsmasq for dhcp and dns on wlp3s0
dnsmasq -R -i wlp3s0 -S 8.8.8.8 -F 192.168.8.50,192.168.8.150,255.255.255.0,12h -2 lo

# enable ip forwarding
sysctl -w net.ipv4.ip_forward=1

# for packets being routed through the box, jump to MASQUERADE if the packet will exit
# on enp0s25; causes packets to be rewritten to look like they originated from enp0s25
iptables -t nat -A POSTROUTING -o enp0s25 -j MASQUERADE

# for packets being routed through the box, jump to ACCEPT if they belong to or are
# related to a connection that already exists
iptables -t filter -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# for packets being routed through the box, jump to ACCEPT if they're coming from
# wlp3s0 and leaving on enp0s25
iptables -t filter -A FORWARD -i wlp3s0 -o enp0s25 -j ACCEPT

# start hostapd
hostapd hostapd.conf
