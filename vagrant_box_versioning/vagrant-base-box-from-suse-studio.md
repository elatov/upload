As I was creating an [OpenSUSE base box](/2014/06/create-a-base-opensuse-image-for-vagrant/) for vagrant, I realized that it was still kind of big in size. I wanted to create a minimal base OS of the OpenSUSE Linux Distribution. That is when I ran into [SUSE Studio](https://susestudio.com/). From [SUSE's site](https://www.suse.com/products/susestudio/technical-information/):

> SUSE Studio is a web-based application for building and testing software applications in a web browser. It supports the creation of physical, virtual or cloud-based applications by leveraging the software appliance form-factor. It enables you to build your own application images or appliances based on SUSE Linux Enterprise Server. SUSE Studio is available as an online or onsite version.

You can basically create your own custom image of the SUSE Linux Distribution and customizing every aspect in the process. So let's give it a try, go to **https://susestudio.com/** and login, after you login you will see the available templates:

![opensuse-templates](opensuse-templates.png)

Since we are trying to minimize the size, let's select "Just Enough OS" then scroll down, select the archicture, give this applicance name:


![ss-arch-name-app](ss-arch-name-app.png)

After clicking on "Create Appliance", it will take you to the configuration:

![ss-config-your-app](ss-config-your-app.png)

Then click on "Switch to the Software tab to continue", and it will take you to the software tab where you can customize what RPMs are included in your custom image:

![ss-software-tab](ss-software-tab.png)

Let's add the **sudo** package, since vagrant uses that, (while we are at it let's add **zerofree** and **curl**):

![ss-add-sudo](ss-add-sudo.png)

After that go to the **Configuration** tab, configure the timezone, enable the firewall (after enabling the firewall it will ask you to add the **SuSEfirewall2** package), and add the vagrant user:

![ss-config-tab](ss-config-tab.png)

Then go to the Appliance subsection and configure LVM:

![ss-configure-appliance-subtab](ss-configure-appliance-subtab.png)

Then go to the **Build** Tab and select the "VMware Workstation/Virtualbox Format":

![ss-image-format-drop-down](ss-image-format-drop-down.png)

Then click on **Build** to start the creation of your custom image:

![ss-creating-image](ss-creating-image.png)

After the build is done, you can download it:

![ss-build-finished](ss-build-finished.png)

After you have the file, extract it:

	elatov@kmac:~/download$tar xvzf openSUSE_13.1.x86_64-0.0.2.vmx.tar.gz
	x openSUSE_13.1-0.0.2/
	x openSUSE_13.1-0.0.2/openSUSE_13.1.x86_64-0.0.2.vmx
	x openSUSE_13.1-0.0.2/openSUSE_13.1.x86_64-0.0.2.vmdk

Now let's add a new VM in VirtualBox and point the virtual disk to the extract vmdk file. So start VirtualBox, click on **New** VM, and give it a Name:

![VirtualBox_Name-the_VM](VirtualBox_Name-the_VM)

When it gets to the hard-drive page, select "Use an existing virtual hard drive file" and point to the vmdk:

![vb-select-vmdk](vb-select-vmdk.png)

After the VM is created, disable the USB ports, audio device and the floppy device in the boot menu. Start the VM and follow the instructions laid out [here](2014/06/create-a-base-opensuse-image-for-vagrant/) to finish the customization of the VM. As a side note, it won't bring up the first interface by default so login as root to the appliance and run the following to get an IP via DHCP (then you can see to the VM using port forwarding like before):

	linux-mjbf:~ # dhcpd enp0s3

Then you can ssh into the VM:

	elatov@kmac:~$ssh vagrant@127.0.0.1 -p 2224
	The authenticity of host '[127.0.0.1]:2224 ([127.0.0.1]:2224)' can't be established.
	ECDSA key fingerprint is 2e:2f:a0:c1:61:93:53:8b:d4:e7:57:82:b4:84:99:02.
	Are you sure you want to continue connecting (yes/no)? yes
	Warning: Permanently added '[127.0.0.1]:2224' (ECDSA) to the list of known hosts.
	Password:
	Last login: Thu Jun 12 13:26:29 2014
	Have a lot of fun...
	vagrant@linux-nhp0:~> su -
	Password:
	linux-nhp0:~ # zypper install sudo
	Retrieving repository 'openSUSE_13.1_OSS' metadata .......................[done]
	Building repository 'openSUSE_13.1_OSS' cache ............................[done]
	Retrieving repository 'openSUSE_13.1_Updates' metadata ...................[done]
	Building repository 'openSUSE_13.1_Updates' cache ........................[done]
	Loading repository data...
	Reading installed packages...
	Resolving package dependencies...
	
	The following NEW package is going to be installed:
	  sudo
	
	1 new package to install.
	Overall download size: 726.7 KiB. After the operation, additional 2.7 MiB will
	be used.
	Continue? [y/n/? shows all options] (y): y

Then edit the **sudoers** file:

	linux-nhp0:~ # visudo

and add the following vagrant user right after the root line:

	##
	## User privilege specification
	##
	root ALL=(ALL) ALL
	vagrant ALL=(ALL) NOPASSWD: ALL

then switch back to *vagrant* user and make sure he can run whatever he wants:

	linux-nhp0:~ # logout
	vagrant@linux-nhp0:~> sudo -l
	Matching Defaults entries for vagrant on this host:
	    always_set_home, env_reset, env_keep="LANG LC_ADDRESS LC_CTYPE LC_COLLATE
	    LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC
	    LC_PAPER LC_TELEPHONE LC_TIME LC_ALL LANGUAGE LINGUAS XDG_SESSION_COOKIE",
	    !insults, targetpw
	
	User vagrant may run the following commands on this host:
	    (ALL) ALL
	    (ALL) NOPASSWD: ALL

Add **/usr/sbin** and **/sbin** to the *vagrant*'s user PATH:

	vagrant@linux-nhp0:~> echo "export PATH=/usr/sbin:/sbin:$PATH" >> .profile
	vagrant@linux-nhp0:~> . .profile
	vagrant@linux-nhp0:~> which e2label
	/usr/sbin/e2label
	    
Fix the **/etc/fstab** boot entry to not depend on static uuids:

	vagrant@linux-nhp0:~> sudo e2label /dev/sda1
	BOOT
	vagrant@linux-nhp0:~> sudo vi /etc/fstab

Replace this:

	/dev/disk/by-id/ata-VBOX_HARDDISK_VBee96db4c-eead6c6b-part1 /boot ext3 defaults 1 2

with this:

	LABEL=BOOT /boot ext3 defaults 1 2

Clean up the GRUB menu to not use the same static UUIDs of the harddrives and also disable the graphical boot:

	vagrant@linux-nhp0:~> sudo vi /etc/default/grub

Modify the following lines from:

	GRUB_DISTRIBUTOR=openSUSE_13.1\ \[\ VMX\ \]
	GRUB_CMDLINE_LINUX_DEFAULT=" root=/dev/systemVG/LVRoot disk=/dev/disk/by-id/ata-VBOX_HARDDISK_VBee96db4c-eead6c6b resume=swap quiet splash=silent"

To this:

	GRUB_DISTRIBUTOR=openSUSE_13.1
	GRUB_CMDLINE_LINUX_DEFAULT=" root=/dev/systemVG/LVRoot resume=swap quiet splash=0"

Rebuild **initrd** and the **grub** menu at the same time:

	vagrant@linux-nhp0:~> sudo mkinitrd
	
	Kernel image:   /boot/vmlinuz-3.11.10-11-default
	Initrd image:   /boot/initrd-3.11.10-11-default
	Root device:	/dev/systemVG/LVRoot (mounted on / as ext3)
	Kernel Modules:	thermal_sys thermal processor fan usb-common usbcore ehci-hcd ohci-hcd uhci-hcd xhci-hcd dm-mod dm-log dm-region-hash dm-mirror dm-snapshot scsi_dh scsi_dh_emc scsi_dh_alua scsi_dh_rdac scsi_dh_hp_sw linear
	Features:       acpi dm plymouth block lvm2 resume.userspace resume.kernel

Get the ssh keys for the vagrant setup:

	vagrant@linux-nhp0:~> mkdir .ssh
	vagrant@linux-nhp0:~> sudo zypper install curl
	vagrant@linux-nhp0:~> curl -k https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub > .ssh/authorized_keys
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100   409  100   409    0     0    838      0 --:--:-- --:--:-- --:--:--   838
	vagrant@linux-nhp0:~> chmod 700 .ssh
	vagrant@linux-nhp0:~> chmod 600 .ssh/authorized_keys
	
Confirm sudo and ssh keys are working, from the host machine, run the following:

	elatov@kmac:~$ssh vagrant@127.0.0.1 -p 2224 -i .vagrant.d/insecure_private_key 'sudo date'
	Thu Jun 12 13:43:51 MDT 2014

Install guest additions (mount the iso with VirtualBox Manager):

	vagrant@linux-nhp0:~> sudo zypper in kernel-devel kernel-default-devel gcc make
	vagrant@linux-nhp0:~> sudo mount /dev/dvd /media
	vagrant@linux-nhp0:~> sudo /media/VBoxLinuxAdditions.run
	Verifying archive integrity... All good.
	Uncompressing VirtualBox 4.3.12 Guest Additions for Linux............
	VirtualBox Guest Additions installer
	Removing installed version 4.3.12 of VirtualBox Guest Additions...
	Copying additional installer modules ...
	Installing additional modules ...
	Removing existing VirtualBox non-DKMS kernel modules              done
	Building the VirtualBox Guest Additions kernel modules
	Building the main Guest Additions module                          done
	Building the shared folder support module                         done
	Building the OpenGL support module                                done
	Doing non-kernel setup of the Guest Additions                     done
	Starting the VirtualBox Guest Additions                           done
	Installing the Window System drivers
	Could not find the X.Org or XFree86 Window System, skipping.
	
Before rebooting install zerofree and remove vmware tools:

	vagrant@linux-nhp0:~> sudo zypper install zerofree
	vagrant@linux-nhp0:~> sudo zypper rm open-vm-tools-9.2.3-3.2.1.x86_64 libvmtools0-9.2.3-3.2.1.x86_64

Then reboot and in the grub menu add the **single** option (to boot into single user mode):

![opensuse-grub-menu-add-single](opensuse-grub-menu-add-single.png)

Then run zerofree

	linux-nhp0:~ # mount / -o remount,ro
	linux-nhp0:~ # zerofree -v /dev/mapper/systemVG-LVRoot

Create a box:

	elatov@kmac:~/vagrant-boxes$vagrant package --output vagrant-stu-min-opensuse13-64.box --base studio-opensuse13-64

Upload it to google drive and create a new vagrant box in vagrant cloud (for version control):

- https://googledrive.com/host/0B4vYKT_-8g4IdzQ0eHV5YWZtQU0/vagrant-opensuse13-64.box
- https://vagrantcloud.com/elatov/opensuse13-64/version/1/provider/virtualbox.box