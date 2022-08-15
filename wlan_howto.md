## WLAN Quick HowTo

The kernel currently has a driver compiled as module for the MediaTek MT7610 chip, nothing else.
This chip is found on the ASUS USB AC-51 WiFi dongle.

- Plug in the WLAN USB Dongle.
- Check with `ip addr` or `/sbin/ifconfig` that you got the `wlan0` interface
- List the available WiFi networks with `/sbin/iwlist wlan0 scan | grep ESSID`
- (If not done once already for the current network:) Run `wpa_passphrase "your network ESSID" "network passphrase" > wpa_supplicant.conf` to write the network info to the `wpa_supplicant.conf` config file.

The next steps need to be done as root:
- Connect to the access point with `wpa_supplicant -B -c wpa_supplicant.conf -i wlan0`
- Obtain an IP address with a DHCP client: `dhclient wlan0`

You should now be connected to your selected access point.
Check with `ip addr` or `/sbin/ifconfig wlan0` that the `wlan0` interface has an IP address.
It's listed after `inet`. An example `ifconfig` output:

```
wlan0: flags=-28605<UP,BROADCAST,RUNNING,MULTICAST,DYNAMIC>  mtu 1500
        inet 192.168.150.154  netmask 255.255.255.0  broadcast 192.168.150.255
        ether fc:34:97:28:6a:e6  txqueuelen 1000  (Ethernet)
```

To release the IP address and disconnect (as root):
- `dhclient wlan0 -r`
- `pkill wpa_supplicant`
