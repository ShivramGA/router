#!/bin/bash

### BEGIN INIT INFO
# Provides: fw.sh
# Required-Start: $syslog
# Required-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Firewall
# Description: Este router se utilizara como encaminador y también tendrá un firewall para filtrar
### END INIT INFO

#nombres de sitios
endor_dmz=192.168.25.0/24
endor_local=192.168.15.0/24
si2=172.20.202.0/24
dns_dmz=192.168.25.2
www_dmz=192.168.25.3
mail_dmz=192.168.25.4
voip_dmz=192.168.25.5
ad_local=192.168.15.92
rpi_local=192.168.15.91
printer_local=192.168.15.135

#Encaminador
echo 1 >/proc/sys/net/ipv4/ip_forward

#Limpiar tablas
iptables -F
iptables -X
iptables -t nat -F

#Politicas por defecto de la tabla Filter
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
#Politicas por defecto de la tabla NAT
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT

#Enmascarar
iptables -t nat -A POSTROUTING -o enp5s0 -j MASQUERADE

## -- Inicio(PREROUTING) -- ##

#Redireccionamiento DNS
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 53 -j DNAT --to $dns_dmz
iptables -t nat -A PREROUTING -s $si2 -p udp --dport 53 -j DNAT --to $dns_dmz

#Redireccionamiento Mail
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 25 -j DNAT --to $mail_dmz
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 587 -j DNAT --to $mail_dmz

#Acceso via SSH a la DMZ desde clase
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 50002 -j DNAT --to $dns_dmz:22
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 50003 -j DNAT --to $www_dmz:22
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 50004 -j DNAT --to $mail_dmz:22
iptables -t nat -A PREROUTING -s $si2 -p tcp --dport 50005 -j DNAT --to $voip_dmz:22
#Redireccionamiento Proxy
iptables -t nat -A PREROUTING -s $endor_local -p tcp --dport 80 -j REDIRECT --to-port 3128

## -- Fin(PREROUTING) -- ##

## -- Inicio(INPUT) -- ##

#LOG
iptables -A INPUT -s $si2 -j LOG --log-prefix 'INTENTO DE ACCESO' --log-level 4

#DNS
iptables -A INPUT -p tcp --sport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
#FTP
iptables -A INPUT -p tcp --sport 20:21 -j ACCEPT
#SSH
iptables -A INPUT -s $si2 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s $endor_dmz -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s $endor_local -p tcp --dport 22 -j ACCEPT
#Proxy
iptables -A INPUT -s $endor_local -p tcp --dport 3128 -j ACCEPT

## -- Fin(INPUT) -- ##

## -- Inicio(OUTPUT) -- ##

#DNS
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
#FTP
iptables -A OUTPUT -p tcp --dport 20:21 -j ACCEPT
#SSH
iptables -A OUTPUT -d $si2 -p tcp --sport 22 -j ACCEPT
iptables -A OUTPUT -d $endor_dmz -p tcp --sport 22 -j ACCEPT
iptables -A OUTPUT -d $endor_local -p tcp --sport 22 -j ACCEPT
#Proxy
iptables -A OUTPUT -d $endor_local -p tcp --sport 3128 -j ACCEPT

## -- Fin(OUTPUT) -- ##

## -- Inicio(FORWARD) -- ##

#DNS
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --sport 53 -j ACCEPT
iptables -A FORWARD -p udp --sport 53 -j ACCEPT
#FTP
iptables -A FORWARD -p tcp --dport 20:21 -j ACCEPT
iptables -A FORWARD -p tcp --sport 20:21 -j ACCEPT
#HTTP
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT #http
iptables -A FORWARD -p tcp --sport 80 -j ACCEPT #http
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT #https
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT #https
#MAIL
iptables -A FORWARD -p tcp --dport 25 -j ACCEPT #smtp
iptables -A FORWARD -p tcp --sport 25 -j ACCEPT #smtp
iptables -A FORWARD -p tcp --dport 110 -j ACCEPT #POP3
iptables -A FORWARD -p tcp --sport 110 -j ACCEPT #POP3
iptables -A FORWARD -p tcp --dport 143 -j ACCEPT #IMAP
iptables -A FORWARD -p tcp --sport 143 -j ACCEPT #IMAP
iptables -A FORWARD -p tcp --dport 587 -j ACCEPT #smtp TLS
iptables -A FORWARD -p tcp --sport 587 -j ACCEPT #smtp TLS
iptables -A FORWARD -p tcp --dport 993 -j ACCEPT #IMAP TLS
iptables -A FORWARD -p tcp --sport 993 -j ACCEPT #IMAP TLS
iptables -A FORWARD -p tcp --dport 995 -j ACCEPT #POP3 TLS
iptables -A FORWARD -p tcp --sport 995 -j ACCEPT #POP3 TLS
iptables -A FORWARD -p tcp --dport 7071 -j ACCEPT #Zimbra admin panel
iptables -A FORWARD -p tcp --sport 7071 -j ACCEPT #Zimbra admin panel
#CHAT
iptables -A FORWARD -p tcp --dport 6667 -j ACCEPT #inspircd chat SSL port
iptables -A FORWARD -p tcp --sport 6667 -j ACCEPT #inspircd chat SSL port
#SSH
iptables -A FORWARD -s $endor_local -d $endor_dmz -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s $endor_dmz -d $endor_local -p tcp --sport 22 -j ACCEPT
iptables -A FORWARD -s $endor_dmz -d $si2 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s $si2 -d $endor_dmz -p tcp --sport 22 -j ACCEPT
iptables -A FORWARD -s $endor_local -d $si2 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s $si2 -d $endor_local -p tcp --sport 22 -j ACCEPT
iptables -A FORWARD -s $si2 -d $endor_dmz -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s $endor_dmz -d $si2 -p tcp --sport 22 -j ACCEPT

## -- Fin(FORWARD) -- ##

##PING
iptables -A INPUT -p ICMP -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p ICMP -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p ICMP -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
