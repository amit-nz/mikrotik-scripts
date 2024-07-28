# Mikrotik - Add IoT (or Guest) VLAN

# Add a new the VLAN to the bridge
# replace comment=, name= and vlan-id= as desired
/interface vlan add comment="V222_IoT - For IoT Devices 192.168.78.0/24" interface=bridge mtu=1492 name=V222_IoT vlan-id=222

# Give it an IP
# Adjust as adress= and network= as needed
/ip address add address=192.168.78.1/24 interface=V222_IoT network=192.168.78.0

# Setup DHCP server
# Adjust IP Ranges per requirements
/ip dhcp-server network add address=192.168.78.0/24 comment="Config for V222_IoT" dns-server=192.168.78.1 gateway=192.168.78.1
/ip dhcp-server add address-pool=pool-V222_IOT comment="DHCP Server for V222_IoT" interface=V222_IoT name=DHCP_V222_IoT
/ip pool add comment="DHCP Pool for V222_IOT" name=pool-V222_IOT ranges=192.168.78.2-192.168.78.20

# Setup new interface lists (for firewalling / mac-server access control)
/interface list add name=LAN_Untrusted
/interface list add name=LAN_Trusted
/interface list member add interface="bridge" list=LAN_Trusted
/interface list member add interface=V222_IoT list=LAN_Untrusted
# Stop the MAC server from listening on the "LAN" address list, and only on the "LAN_Trusted" address list
/tool mac-server set allowed-interface-list=LAN_Trusted
/tool mac-server mac-winbox set allowed-interface-list=LAN_Trusted
# Add the IoT VLAN to "LAN" (or else it wont get NAT'ed for internet access)
/interface list member add interface=V222_IoT list=LAN

# Firewalling - Prevent untrusted LANs from being able to access other LANs. Adjust ordering if necesary.
/ip firewall filter add action=drop chain=forward comment="Dont allow traffic into LANPRIVATE from other VLANs" in-interface-list=LAN_Untrusted out-interface-list=LAN

# Optional - add static leases (if any)
/ip dhcp-server lease
add mac-address=aa:bb:cc:dd:ee:ff address=192.168.78.2 comment=dehumidifier

# Also Optional - in some cases, IoT devices won't respond to commands coming from outside the subnet 
# (for e.g. like if your Home Assistant is in your trusted LAN and and your IoT stuff is in another.
# In this case, use a NAT rule like so 
# dst-address = IP of host in IoT VLAN
# out-interface = name of the IoT Interface
# src-address = IP of the host generating the traffic (e.g. HomeAssistant)
# to-address = the IP of the router's LAN interface in the IoT VLAN 
/ip firewall nat add action=src-nat chain=srcnat comment="IoT - Make traffic look like its coming from the same LAN to Host" dst-address=192.168.78.2 out-interface=V222_IoT src-address=192.168.81.2 to-addresses=192.168.78.1
