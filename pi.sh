#!/bin/bash

sudo ip addr add 10.80.1.1/24 broadcast 10.80.1.255 dev enp2s0
sudo sysctl net.ipv4.ip_forward=1
sudo systemctl start dhcpd4@enp2s0
sudo iptables -t nat -A POSTROUTING -o wlp3s0 -j MASQUERADE

