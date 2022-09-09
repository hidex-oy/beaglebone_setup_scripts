## BeagleBone Setup Scripts

This repository contains the scripts to create the full installation images (or rather just the installation that the image can be created from) starting from a fresh BeagleBone Debian image.

The image that was used for testing is the Console image based on Debian 10.3 here: https://debian.beagleboard.org/images/bone-debian-10.3-console-armhf-2020-04-06-1gb.img.xz


## Creating the base "Hidex image" from an upstream image

The script `beaglebone_fresh_install_setup.sh` is used to create the base installation based on a fresh upstream BeagleBone Debian image.

This base installation contains the custom Hidex Linux kernel, which patches the USB device handling to work around issues in some older devices (wrongly set HID poll interval value).

It also modifies a few config files and downloads a number of scripts and installs a few needed packages.

The config changes include:
* Disable the "tutorial drive" feature and disable the unnecessary/spammy login messages
* Download a new `.bashrc` file with some useful aliases and "nicer prompt color"
* Use the correct PRU Device Tree Overlay (PRU-UIO vs. PRU-RPROC)
* Enable the external DS1307 RTC using another overlay
* Disables the audio and video related overlays, as the HDMI lines are needed for the custom cape in some device versions
* Redirect dnsmasq log output to `/dev/null`
* Setup an `/etc/rc.local` file to disable the bright blue LEDs from the board on every boot, to prevent blue light leakage to the detectors

The script also downloads the additional scripts that are used later on, during the first couple of boots of the final finished image, to automatically expand the partition to fill the SD card, and to enable a swap file.


### Prerequisites

Flash the base BeagleBone Debian 10.3 Console image linked above to an empty SD card. The SD card needs to be at least 1 GB for that image, but the later installation steps create a 2 GB swap file, so realistically it should be at least 8 GB for there to be a decent amount of free space as well.

**Note:** Make sure the SD card doesn't contain anything you care about, as it will get overwritten by the following command!

On Linux the image can be written to the card with the following command, assuming that the SD card is `/dev/mmcblk0`. Unmount the card first, if it got automatically mounted when you inserted it.

**BE SURE TO CHECK THE DEVICE OR YOU CAN OVERWRITE YOUR DATA!!!**

```bash
# Check your block devices, and  make sure you use the correct
# device node that corresponds to the SD card.
lsblk

# Write the image to the card
xzcat bone-debian-10.3-console-armhf-2020-04-06-1gb.img.xz > /dev/mmcblk0

# Flush the buffers before removing the card
sync
```

Insert the SD card to a BeagleBone Black, and then plug the BeagleBone to a PC with a USB cable. The BeagleBone should now boot, and it should create a USB network connection that you can use to log in via ssh to the BeagleBone. The default IP address is `192.168.7.2`. The first boot using the fresh stock image seems to take around 1.5 minutes to fully boot, before the ssh connection can be made.


### Usage

To begin, log in via ssh via the USB network connection at `192.168.7.2`. The username is `debian` and the default password is `temppwd`.
```bash
ssh debian@192.168.7.2
```

Probably the very first thing you want to do is change the password from the default to something else:
```bash
passwd
```

Now before continuing, plug the BeagleBone to a network cable. You will also need to wait for the time to get synced from NTP, before wget is able to connect to any HTTPS addresses due to the certificates failing otherwise.

You can check the current system time with `date`. It should only take something like 20-30 seconds for the time to get synced after the wired network comes up.

First download the `beaglebone_fresh_install_setup.sh` script:
```bash
wget https://raw.githubusercontent.com/hidex-oy/beaglebone_setup_scripts/master/beaglebone_fresh_install_setup.sh
```

**Note: Next you should copy the following four packages to the `/home/debian/hidex_packages/` directory (which you need to create first).**
(These are currently not fetched by the install script, since the repositories are set to private on GitHub.)

* `hidex-beaglebone-cape-eeprom-1.0.0-beta.1_armhf.deb`
* `hidex-beaglebone-configs-1.0.0_armhf.deb`
* `hidex-beaglebone-dtbo-1.0.0-beta.1_armhf.deb`
* `hidex-beaglebone-scripts-1.0.0_armhf.deb`

If or when new versions of these become available, the install script should be updated to refer to the correct package file names.

Then run the install script as root (with sudo):
```bash
sudo bash beaglebone_fresh_install_setup.sh
```

After that script has finished (assuming everything went ok), you should reboot once manually, so that the custom Hidex kernel is used (not that it matters much for anything else yet, but the script deletes the old kernel including the kernel modules):
```bash
sudo /sbin/reboot
```

After that reboot you basically want to install all the rest of the packages, such as the Hidex Control Platform version you want to use and any plugins and device config/script packages etc.

Once everything is installed, enable the "staged boot setup scripts" by running the script `/usr/local/bin/beaglebone_staged_setup_enable.sh`.
```bash
sudo bash /usr/local/bin/beaglebone_staged_setup_enable.sh
```
(This basically just uncomments the `/usr/local/bin/beaglebone_staged_setup_boot_main.sh` line in the `/etc/rc.local` file, so that the script will be run on each boot until it gets disabled again.)

At this point **you don't want to reboot for any reason** until you have taken the final image of the installation, as the next reboot will start the file system expansion cycle:

* on the first boot expand the root partition to cover the entire SD card
* on the second boot run fsck and expanding the filesystem itself by running `resize2fs`
* on the third boot create a 2 GB swap file and enable it by adding it to the `/etc/fstab` file
* also on the third boot disable these staged start scripts by commenting out the main call to `/usr/local/bin/beaglebone_staged_setup_boot_main.sh` from `/etc/rc.local`

So basically at this point, after running the above script to enable the staged boot scripts, just shutdown the system and take a disk image:
```bash
sudo /sbin/shutdown -h now
```

Now unplug the BeagleBone from the PC and take out the SD card, and take a disk image.

If you use Win32 Disk Imager to take the image, then enable the option `Read Only Allocated Partitions`. Next you also probably want to compress that image using 7-zip and the `xz` Archive format. At least the Balena Etcher image flasher can directly read that compressed image, and this way the image takes as little space as feasible.

On Linux you can take a disk image with the `dd` utility. For that you want to check the partition table on the card, and only read from the start of the card to the end of the first and only partition on the card.
**Note that you need to check what device the card appears as in your case (with `lsblk` and/or `df -h` and/or `dmesg | less`)!!**
Here it is `/dev/mmcblk0`:

```bash
sudo fdisk -l /dev/mmcblk0
```

Example output:
```
debian@beaglebone ~ $  sudo fdisk -l /dev/mmcblk0
Disk /dev/mmcblk0: 29.7 GiB, 31914983424 bytes, 62333952 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x411292eb

Device         Boot Start     End Sectors  Size Id Type
/dev/mmcblk0p1 *     8192 1843199 1835008  896M 83 Linux
```

Here the End sector is `1843199`, thus there are 1843200 sectors of data (starting from 0) until the end of that partition.
So the command to read a disk image from the card, and compress it on the fly, would be:

```bash
sudo dd if=/dev/mmcblk0 bs=512 count=1843200 | lzma -9 > bbb_image.img.xz
```


## Using the finished disk image

The finished disk image, where the "staged" setup scripts have been enabled, will automatically expand the partition on the first boot to cover the available space on the SD card. And on the second boot it will create, setup and enable a 2 GB swap file on the root partition, using the file `/swapfile`.

So the only thing the user has to do, is to write that image to an empty SD card, insert the card to a BeagleBone Black, and boot it. The automated setup will take a few minutes (about 5 - 10 minutes), and once it's finished, the 4 blue user LEDs on the board will do a cycling LED bar animation. After this everything should be finished and ready for use.

If WiFi network access is required, there is a short howto text document in the home directory. The installation image only contains the driver and firmware for the MediaTek MT7610 chip, which is used at least on the Asus USB-AC51 USB WiFi dongle.
