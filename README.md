## BeagleBone Setup Scripts

This repository contains the scripts to create the full installation images (or rather just the installation that the image can be created from) starting from a fresh BeagleBone Debian image.

The image that was used for testing is the Console image based on Debian 10.3 here: https://debian.beagleboard.org/images/bone-debian-10.3-console-armhf-2020-04-06-1gb.img.xz

## Creating the base "Hidex image" from an upstream image

The script `beaglebone_fresh_install_setup.sh` is used to create the base installation based on a fresh upstream BeagleBone Debian image.

This base installation contains the custom Hidex Linux kernel, which patches the USB device handling to work around issues in some older devices (wrongly set HID poll interval value).

It also modifies a few config files, to disable the "tutorial drive" feature, and to use the correct PRU Device Tree Overlay, and also to enable the external DS1307 RTC using another overlay. Additionally it disables the audio and video related overlays, and it redirects dnsmasq log output to `/dev/null`.

And finally the script downloads the additional script files that are then later used during the first boots of the final finished image, to automatically expand the partition to fill the SD card, and to enable a swap file.

### Prerequisite

Flash the base BeagleBone Debian 10.3 Console image linked above to an empty SD card. The SD card needs to be at least 1 GB for that image, but the later installation steps create a 2 GB swap file, so realistically it should be at least 8 GB for there to be a decent amount of free space as well.

Insert the SD card to a BeagleBone Black, and then plug the BeagleBone to a PC with a USB cable. The BeagleBone should now boot, and it should create a USB network connection that you can use to log in via ssh to the BeagleBone, using address `192.168.7.2`. The first boot using the fresh stock image seems to take around 1.5 minutes to fully boot, before the ssh connection can be made.


### Usage

To begin, log in via ssh via the USB network connection at `192.168.7.2`. The username is `debian` and the default password is `temppwd`.
```bash
ssh debian@192.168.7.2
```

Probably the very first thing you want to do is change the password from the default to something else:
```bash
passwd
```

Now before continuing, plug the BeagleBone to a network cable.

First download the `beaglebone_fresh_install_setup.sh` script:

```bash
wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/beaglebone_fresh_install_setup.sh
```

Then run that script as root (with sudo):
```bash
sudo bash beaglebone_fresh_install_setup.sh
```

After that script is finished (assuming everything went ok), you should reboot once manually, so that the custom Hidex kernel is used (not that it matters for anything else yet, but the script deletes the modules for the default kernel):

Note that you probably want to unplug the network cable now (and before any time the BeagleBone is rebooted), as it seems like the USB network connection doesn't come up if the network cable is plugged in. Of course you could then also just use that wired network connection to ssh in (if you know the IP) instead of the USB connection at `192.168.7.2`. If you want to use the wired connection, then you probably want to first log in once via the USB connection, so that you can use `ip addr` to find out the IP address for that network interface.

```bash
sudo /sbin/reboot
```

After that reboot you basically want to install all the rest of the packages, such as the Hidex Control Platform version you want to use and any plugins and device config/script packages etc.

Once everything is installed, enable the "staged boot setup scripts" by running the script `/usr/local/bin/beaglebone_enable_staged_boot_scripts.sh`:
```bash
sudo bash /usr/local/bin/beaglebone_enable_staged_boot_scripts.sh
```

At this point **you don't want to reboot for any reason** until you have taken the final image of the installation, as the next reboot will start the cycle of:

* on the first boot expand the root partition to cover the entire SD card
* on the second boot run fsck and expanding the filesystem itself by running `resize2fs`
* on the third boot create a 2 GB swap file and enable it by adding it to the `/etc/fstab` file
* also on the third boot disable these staged start scripts by commenting out the main call to `/usr/local/bin/beaglebone_boot_staged_setup.sh` from `/etc/rc.local`

So basically at this point, after running the above script to enable the staged boot scripts, just shutdown the system and take a disk image:
```bash
sudo /sbin/shutdown -h now
```

Now unplug the BeagleBone from the PC and take out the SD card, and take a disk image.

If you use Win32 Disk Imager to take the image, then enable the option `Read Only Allocated Partitions`. Next you also probably want to compress that image using 7-zip and the `xz` Archive format. At least the Balena Etcher image flasher can directly read that compressed image, and this way the image takes as little space as feasible.
