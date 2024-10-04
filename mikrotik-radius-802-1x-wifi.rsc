# NOTE PKI/Cert/CA setup & cert deployment not covered here and assumes you already have a RADIUS server (like FreeRadius / Windows NPS / Duo Auth Proxy or similar) listening on port 1812 
# NOTE2 using a self-signed PKI throws errors on most modern OSes and some do not allow bypassing. Therefore it may be necessary to deploy certificates via GPO/MDM to clients.

# Add a RADIUS server details (edit address, secret and src-address as needed)
/radius add address=radius-server.mydomain.com secret=super-secret-passphrase service=wireless src-address=192.168.88.1

# Add the Wi-Fi security profile
/interface wireless security-profiles add authentication-types=wpa2-eap disable-pmkid=no eap-methods=passthrough group-ciphers=aes-ccm mode=dynamic-keys name="profile_RADIUS_WiFi" supplicant-identity=""

# Setup the interfaces (edit interface names / country / SSID as necessary)
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-XX country="new zealand" disabled=no distance=indoors frequency=auto installation=indoor\
mode=ap-bridge security-profile="profile_RADIUS_WiFi" ssid="RADIUS WiFi" wireless-protocol=802.11 wps-mode=disabled

set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=20/40/80mhz-XXXX country="new zealand" disabled=no distance=indoors frequency=auto installation=indoor\
mode=ap-bridge security-profile="profile_RADIUS_WiFi" ssid="RADIUS WiFi" wireless-protocol=802.11 wps-mode=disabled
