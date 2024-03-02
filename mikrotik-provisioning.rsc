# Read fully before using, various sections need to be replaced as needed.

# Set Hostname
/system identity set name=router.mydomain.com

# Change admin pw & add a user for yourself
/user set 0 password="blahblah12346"
# Change name ;)
/user add name=amit group=full

# Disable DHCP Client (unless needed). 
# Use "/ip dhcp-client print" to identify existing DHCP clients)
/ip dhcp-client disable numbers=

# Disable + remove Factory DHCP servers & pools
/ip dhcp-server disable [ find where name="defconf" ]
/ip dhcp-server network remove numbers= [ find where comment ="defconf" ]
/ip pool remove [ find where name="default-dhcp" ]

# Setup DHCP Server (adjust IPs as needed)
# Add a pool with IPs that will be leased out
/ip pool add name=dhcp-pool-LANPrivate ranges=10.94.44.50-10.94.44.119
# Setup DHCP server
/ip dhcp-server add address-pool=dhcp-pool-LANPrivate disabled=no interface=bridge name=DHCP_LANPrivate
# Setup misc options
/ip dhcp-server network add address=10.94.44.0/24 comment=DHCP_LANPrivate_IPRange dns-server=<IP OF LOCAL INTERFACE TO QUERY FROM> domain=mydomain.local gateway=<IP OF LOCAL INTERFACE TO QUERY FROM> netmask=24

# Change bridge IP to match our LAN - update 10.94.44.254 with desired IP & renew/release your system before continuing 
/ip address set [/ip address find address="192.168.88.1/24"] address=10.94.44.254/24

# Add Static DHCP leases (adjust mac, IP, server name etc as needed)
/ip dhcp-server lease
add mac-address=80:5e:c0:aa:bb:cc address=10.94.44.120 comment=t19p_reception
add mac-address=80:5e:c0:aa:bb:dd address=10.94.44.121 comment=t19p_accounts

# PPPoE Config - replace "WAN_CLICKNET" if required, and insert relevant detils in user= and password=
interface vlan add vlan-id=10 interface=ether1 name=vlan10
interface pppoe-client add interface=vlan10 name=WAN_CLICKNET user=abc@clicknet.nz password=abcd use-peer-dns=yes add-default-route=yes
interface pppoe-client enable WAN_CLICKNET

# Add WAN interface just added or else default NAT rule wont work
/interface list member add interface=WAN_CLICKNET list=WAN

# Prevent MAC server from listening on WAN 
################
################   SUPERFLUOUS on 7.8 and up, mac-server only listens on LANs. But a good idea to fine tune this.
################
# Create an interface list that lists all the interfaces MAC server services should listen on
/interface list member add comment=LANPRIV interface=bridge list=LAN
# Lock down MAC server
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN
/tool mac-server set allowed-interface-list=LAN
/tool mac-server mac-winbox set allowed-interface-list=LAN

# Disable LLDP-med / ND 
/ip neighbor discovery-settings set discover-interface-list=none

# IPv6 configs - ensure ipv6 package is installed & enabled first.
###############
################# These are just the default address list entries; can skip them if they already exist (i.e. newer routers have these in defconf)
################
# Address lists first
/ipv6 firewall address-list
add address=::/128 comment="unspecified address" list=bad_ipv6
add address=::1/128 comment=lo list=bad_ipv6
add address=fec0::/10 comment=site-local list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment=ipv4-mapped list=bad_ipv6
add address=::/96 comment="ipv4 compat" list=bad_ipv6
add address=100::/64 comment="discard only " list=bad_ipv6
add address=2001:db8::/32 comment=documentation list=bad_ipv6
add address=2001:10::/28 comment=ORCHID list=bad_ipv6
add address=3ffe::/16 comment=6bone list=bad_ipv6
# Trusted host setup for IPv6
# Optional - trused host address list, will give these full access into network later
add address=ffff:1e00:9d01:aaa::/64 comment=Trusted.1 list=TrustedHosts_IPv6
add address=ffff:1e00:b910:bbbb::/64 comment=Trusted.2 list=TrustedHosts_IPv6

# FW Rules - IPV6 - Note, this assumes NO rules are in place yet.

# General ipv6 rules
/ipv6 firewall filter
add action=accept chain=forward comment="Allow all on WAN from Trusted into LAN" src-address-list=TrustedHosts_IPv6 place-before=1
add action=accept chain=input comment="Allow all on WAN from Trusted to WAN" src-address-list=TrustedHosts_IPv6 place-before=1
###############
################# These are just the default rules; can skip them if they already exist (i.e. newer routers have these in defconf)
################
add action=accept chain=input comment="accept established,related,untracked" connection-state=established,related,untracked
add action=drop chain=input comment="drop invalid" connection-state=invalid
add action=accept chain=input comment="accept ICMPv6" protocol=icmpv6
add action=accept chain=input comment="accept UDP traceroute" port=33434-33534 protocol=udp
add action=accept chain=input comment="accept DHCPv6-Client prefix delegation." dst-port=546 protocol=udp src-address=fe80::/10
add action=accept chain=input comment="accept IKE" dst-port=500,4500 protocol=udp
add action=accept chain=input comment="accept ipsec AH" protocol=ipsec-ah
add action=accept chain=input comment="accept ipsec ESP" protocol=ipsec-esp
add action=accept chain=input comment="accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment="drop everything else not coming from LAN" in-interface-list=!LAN
add action=accept chain=forward comment="accept established,related,untracked" connection-state=established,related,untracked
add action=drop chain=forward comment="drop invalid" connection-state=invalid
add action=drop chain=forward comment="drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment="drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="rfc4890 drop hop-limit=1" hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="accept ICMPv6" protocol=icmpv6
add action=accept chain=forward comment="accept HIP" protocol=139
add action=accept chain=forward comment="accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment="drop everything else not coming from LAN" in-interface-list=!LAN
# Accept ipv6 ah/esp - consider locking down to trusted hosts with "src-address-list=TrustedHosts_IPv6" and adding remote VPN concentrator IPs to this list
add action=accept chain=forward comment="accept IKE" dst-port=500,4500 protocol=udp
add action=accept chain=forward comment="accept ipsec AH" protocol=ipsec-ah
add action=accept chain=forward comment="accept ipsec ESP" protocol=ipsec-esp

# Addressing - grab IPv6 via ISP 
/ipv6 dhcp-client add add-default-route=yes interface=WAN_CLICKNET pool-name=delegation prefix-hint=::/56 request=prefix
/ipv6 nd add interface=bridge ra-interval=20s-1m
# Assign ::1 to the LAN interface of the router
/ipv6 address add address=::1 from-pool=delegation interface=bridge
# Setup dhcp server to hand addresses out to LAN hosts (Caution: this command won't work unless you have a pd from the ISP)
/ipv6 dhcp-server add interface=bridge name=LANPrivate-dhcp6-server
# At this point check if LAN host has ipv6 connectivity

# Prevent neighbour discovery on WAN interface
# Note: Superfluous on newer devices/fw levels
/ip neighbor discovery-settings set discover-interface-list=LAN

# Setup a self-signed SSL cert for WebGUI
# Setup a CA
/certificate add name=root-cert common-name=router-CA days-valid=3650 key-usage=key-cert-sign,crl-sign
/certificate sign root-cert
# Setup a cert - replace common-name
/certificate add name=webui-https-cert common-name=router.mydomain.com days-valid=3650
/certificate sign ca=root-cert webui-https-cert
# Assign cert to www-ssl, enable it if disabled, disable HTTP & other services as needed + add IP whitelist
/ip service set www-ssl address=10.94.44.0/24,10.94.43.0/24,1.2.3.4/32,4.3.2.1./32 certificate=webui-https-cert disabled=no
# Now test if HTTPS is working, and if it is disable the HTTP management
/ip service set www disabled=yes

# Disable uneeded services, restrict allowed services by IP (update IPs and services as needed needed)! 
# Also need FW rules updated!
/ip service disable telnet,api,api-ssl,ftp
/ip service set ssh address=10.94.44.0/24,10.94.43.0/24,1.2.3.4/32,4.3.2.1./32
/ip service set winbox address=10.94.44.0/24,10.94.43.0/24,1.2.3.4/32,4.3.2.1./32

# FW Rules - IPV4 - Note, this assumes basic IPv4 rules are in place already.
# FW Aliases first
/ip firewall address-list
add address=1.2.3.4 comment="Trusted 1" list=TrustedHosts_IPv4
add address=4.3.2.1 comment="Trusted 2" list=TrustedHosts_IPv4
# Then rules (these may need to be re-ordered)
/ip firewall filter 
add action=accept chain=input comment="Allow Winbox on WAN from Trusted" in-interface=WAN_CLICKNET port=8291 protocol=tcp src-address-list=TrustedHosts_IPv4 place-before=1
add action=accept chain=input comment="Allow SSL-WEB on WAN from Trusted" in-interface=WAN_CLICKNET port=443 protocol=tcp src-address-list=TrustedHosts_IPv4 place-before=1
add action=accept chain=input comment="Allow SSH on WAN from Trusted" in-interface=WAN_CLICKNET port=22 protocol=tcp src-address-list=TrustedHosts_IPv4 place-before=1
add action=accept chain=input comment="Allow SNMP on WAN from Trusted" in-interface=WAN_CLICKNET port=161 protocol=udp src-address-list=TrustedHosts_IPv4 place-before=1
# IF PLANNING ON USING IPSEC ADD THIS RULE, BEFORE ANY DROP RULES. Consider 
/ip firewall filter add action=accept chain=input comment="Allow IPSEC traffic from F_DC Only" protocol=ipsec-esp src-address-list=TrustedHosts_IPv4 place-before=1

# IPSEC - replace "tunnel_To_RemoteSite1" and "Tunnel_IP4_To_Remote_Office", IPSEC Secret and subnets:
# IPSEC P1s - update peer configs
/ip ipsec peer
add address=123.123.123.123/32 exchange-mode=ike2 name=Tunnel_IP4_To_Remote_Office
add address=ffff:abcd:4005:aaaa::2/128 exchange-mode=ike2 name=Tunnel_IP6_To_Remote_Office
# IPSEC Enc Algos
/ip ipsec profile
set [ find default=yes ] dh-group=modp2048 enc-algorithm=aes-128 hash-algorithm=sha256 prf-algorithm=sha256
/ip ipsec proposal
set [ find default=yes ] auth-algorithms=sha256 enc-algorithms=aes-256-gcm,aes-192-ctr,aes-128-gcm pfs-group=modp2048
# IPSEC P2s. Replace below subnets as requried
/ip ipsec identity
add peer=Tunnel_IP4_To_Remote_Office secret=super_duper_ipsec_ipv4_secret
add peer=Tunnel_IP6_To_Remote_Office secret=super_duper_ipsec_ipv6_secret
/ip ipsec policy
add dst-address=10.94.43.0/24 peer=Tunnel_IP4_To_Remote_Office src-address=10.94.44.0/24 tunnel=yes
add dst-address=aaaa:bbbb:4005:ffff::/64 peer=Tunnel_IP6_To_Remote_Office src-address=ffff:1e00:bbbb:aaa::/56 tunnel=yes
# IPSEC Related IPv4 rules (change src-address and dst-address as needed)
/ip firewall filter 
add action=accept chain=input comment="IPSEC - Inbound from RemoteOffice to LAN" src-address=10.94.44.0/24
add action=accept chain=output comment="IPSEC - Outbound to LAN to RemoteOffice" dst-address=10.94.44.0/24
# IPSEC Related IPv6 rules (change src-address and dst-address as needed)
/ipv6 firewall filter
add action=accept chain=forward comment="Allow inbound traffic from DC to LAN" src-address=ffff:1e00:bbbb:aaa::/56
add action=accept chain=output comment="Allow outbound traffic to DC to LAN" dst-address=aaaa:bbbb:4005:ffff::/64

#Optional - Conditional DNS Forwarder for non-fqdn AD setups - replace "mydomain.local", <IP OF LOCAL INTERFACE TO QUERY FROM> and <IP OF REMOTE DNS SERVER>
/ip firewall layer7-protocol add comment=dns_forwarder name=mydomain.local regexp=mydomain.local
/ip firewall mangle add action=mark-connection chain=prerouting comment=dns_forwarder dst-address=<IP OF LOCAL INTERFACE TO QUERY FROM> dst-port=53 layer7-protocol=mydomain.local new-connection-mark=mydomain.local-forward passthrough=yes protocol=tcp place-before=1
/ip firewall mangle add action=mark-connection chain=prerouting comment=dns_forwarder dst-address=<IP OF LOCAL INTERFACE TO QUERY FROM> dst-port=53 layer7-protocol=mydomain.local new-connection-mark=mydomain.local-forward passthrough=yes protocol=udp place-before=1
/ip firewall nat add action=dst-nat chain=dstnat comment=dnsforwarder_dstnat connection-mark=mydomain.local-forward to-addresses=<IP OF REMOTE DNS SERVER>
/ip firewall nat add action=masquerade chain=srcnat comment=dnsforwarder_srcnat connection-mark=mydomain.local-forward out-interface-list=LAN
/ip firewall nat add action=masquerade chain=srcnat comment="NAT for internet access" ipsec-policy=out,none out-interface-list=WAN
# Disable builtin NAT rule
/ip firewall nat disable numbers= [ find where comment ="defconf: masquerade" ]

# SNMPv3 monitoring - replace "addresses=" (dont forget to open fw if needed) and auth passswords. Update address and contact.
/snmp community
set [ find default=yes ] addresses=1.2.3.4/32 authentication-password=SUPER_SECURE_AUTHPW authentication-protocol=SHA1 encryption-password=SOOPER_SECURE_ENCPW \
    encryption-protocol=AES security=private
/snmp set contact=no@reply.nrp enabled=yes location="ADDRESS_GOES_HERE" trap-generators=""

# Add any NAT rules aka "PORT FORWARDING" (if necessary)
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-port=80 in-interface=WAN protocol=tcp to-addresses=10.94.44.5 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-port=443 in-interface=WAN protocol=tcp to-addresses=10.94.44.5 to-ports=443

# Import ssh key for pubkey login for user added earlier
/tool fetch https://link.to/my/id_rsa.pub
/user ssh-keys import public-key-file=id_rsa.pub user=amit
