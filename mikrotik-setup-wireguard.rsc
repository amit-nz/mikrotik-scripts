# Mikrotik - Wireguard S2S -or- Road Warrior (remote access) VPN Setup 


# Add wireguard interface 
# Replace listen-port=, name= as desired. 
# Omit Private-Key= if not migrating from another wg setup and it will be generated. 
# Adjust port= if necessary
# Optional but recommended: change wg0 in "name=wg0" to something meaningful so identifying it later is easier
/interface wireguard add listen-port=51823 mtu=1420 name=wg0 private-key=""

# Add peer (needed for both S2S and Remote Access)
# If S2S: Replace allow-address= with comma-separated networks on the remote side of the wg tunnel
# And replace endpoint-address= w/ WAN IP (or DNS name) of remote wireguard terminator
# If Remote Access, replace allow-address= with /32 of remote host and omit endpoint-address & endpoint-port blank. 
#
# interface= must match name from previous section; Replace public-key w/ remote side's pubkey
/interface wireguard peers
add allowed-address=10.0.0.0/24,10.12.32.0/24 endpoint-address=1.2.3.4 endpoint-port=51823 interface=wg0 public-key=""

# Not needed for S2S - only Remote Access
# Add IP addresses - this is not necessary for S2S, but is necessary for P2P.
# interface= must match name of wg interface from previous section. If S2S, this range must not conflict with remote side
/ip address add address=10.64.12.2/24 interface=wg0 network=10.64.12.0

# Not needed for Remote Access - only for S2S
# Add routes -- these are the LANs on the remote side so the mikrotik knows where to send the traffic
# Replace comment= and gateway= must match name from previous sections
# dst-address= should be networks (1 on each line) of the remote side in CIDR format
/ip route
add comment="Route for SubnetA" disabled=no dst-address=10.0.0.0/24 gateway=wg0 routing-table=main suppress-hw-offload=no
add comment="Route for SubnetB" disabled=no dst-address=10.12.32.0/24 gateway=wg0 routing-table=main suppress-hw-offload=no

# Firewall Rules:
# Open listen-port in the firewall from WAN or else this won't work - note ordering.
/ip firewall filter add action=accept chain=input comment="Wireguard" dst-port=51823 in-interface=WAN protocol=udp
# Add firewall rules as needed (needed for both S2S and Remote Access) - note ordering.
/ip firewall filter add action=accept chain=forward comment="Wireguard | Allow inbound" src-address=10.0.0.0/24
# Note - don't forget to add fw rules to the "input" chain for DNS if intending to use Mikrotik for DNS.