### Pre-requesites:
### (1) Working internet connection
### (2) An external domain A record aimed at the IP address of your internet connection (update this on line 22)
### (3) Acceptance of a small degree of risk that the WebGui your system will be accessible to the internet while the cert is being generated

# Backup current service config so we can put it back when we're done
/ip/service/export file=ip_service_backup

# Add temporary firewall rule so LE-SSL challenge can access us
/ip/firewall/filter/add action=accept chain=input comment="LeSSL Temporary FW Rule" in-interface=WAN_UFB port=80 protocol=tcp src-address=0.0.0.0/0  place-before=2
/ip/firewall/filter/add action=accept chain=input comment="LeSSL Temporary FW Rule" in-interface=WAN_UFB port=443 protocol=tcp src-address=0.0.0.0/0  place-before=2

# Edit the service whitelist, ports, state etc 
/ip/service/set www address=0.0.0.0/0
/ip/service/set www port=80
/ip/service/set www disabled=no
/ip/service/set www-ssl address=0.0.0.0/0
/ip/service/set www-ssl port=443
/ip/service/set www-ssl disabled=no

# Get cert
/certificate/enable-ssl-certificate dns-name=router.mydomain.com

# Put the old configs back
/ip firewall filter remove  [ find where comment ="LeSSL Temporary FW Rule" ]
/import file-name=ip_service_backup.rsc
/file/remove ip_service_backup.rsc

# Todo: 
# Automatically update cert for use in WebGUI and anywhere else it is needed.