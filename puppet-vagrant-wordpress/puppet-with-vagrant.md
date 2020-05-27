Let's do a simple example to use **puppet** to update the system. Make sure the guest has puppet installed:

	linux-mjbf:~ # zypper install puppet
	vagrant@linux-mjbf:~> rpm -q puppet
	puppet-3.2.4-3.1.1.x86_64

Then build another box from that OS and upload it to the vagrant cloud. Now let's init the environment with the newly updated box:

	elatov@kmac:~$mkdir test2
	elatov@kmac:~$cd test2
	elatov@kmac:~/test2$vagrant init elatov/opensuse13-64
	A `Vagrantfile` has been placed in this directory. You are now
	ready to `vagrant up` your first virtual environment! Please read
	the comments in the Vagrantfile as well as documentation on
	`vagrantup.com` for more information on using Vagrant.

Now let's prepare a simple **manifest** to update the system:

	elatov@kmac:~/test2$mkdir manifests
	elatov@kmac:~/test2$vi manifests/default.pp

Add the following to the file:

	exec { "zypper update -y":
	  path => "/usr/bin",
	}
	
Now let's configure the VagrantFile to use **puppet** as the provisioner:

	elatov@kmac:~/test2$grep -vE '^  #|^$' Vagrantfile
	# -*- mode: ruby -*-
	# vi: set ft=ruby :
	# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
	VAGRANTFILE_API_VERSION = "2"
	Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	  config.vm.box = "elatov/opensuse13-64"
	  config.vm.provision "puppet" do |puppet|
	     puppet.manifests_path = "manifests"
	     puppet.manifest_file  = "default.pp"
	   end
	end
	
Now let's try it out:


	elatov@kmac:~/test2$vagrant up
	Bringing machine 'default' up with 'virtualbox' provider...
	==> default: Importing base box 'elatov/opensuse13-64'...
	==> default: Matching MAC address for NAT networking...
	==> default: Checking if box 'elatov/opensuse13-64' is up to date...
	==> default: Setting the name of the VM: test2_default_1403537849585_40825
	==> default: Clearing any previously set network interfaces...
	==> default: Preparing network interfaces based on configuration...
	    default: Adapter 1: nat
	==> default: Forwarding ports...
	    default: 22 => 2222 (adapter 1)
	==> default: Booting VM...
	==> default: Waiting for machine to boot. This may take a few minutes...
	    default: SSH address: 127.0.0.1:2222
	    default: SSH username: vagrant
	    default: SSH auth method: private key
	    default: Warning: Connection timeout. Retrying...
	==> default: Machine booted and ready!
	==> default: Checking for guest additions in VM...
	==> default: Mounting shared folders...
	    default: /vagrant => /Users/elatov/test2
	    default: /tmp/vagrant-puppet-3/manifests => /Users/elatov/test2/manifests
	==> default: Running provisioner: puppet...
	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//Exec[zypper update -y]/returns: executed successfully
	==> default: Notice: Finished catalog run in 0.21 seconds
	
We can see that the command went through without issues:

	==> default: Running provisioner: puppet...
	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//Exec[zypper update -y]/returns: executed successfully
	
Now let's try to install a package with **zypper**. Make sure the **puppet** version that is on the guest supports **zypper**:

	vagrant@linux-mjbf:~> puppet describe package --providers | grep zypper -A 3
	- **zypper**
	    Support for SuSE `zypper` package manager. Found in SLES10sp2+ and SLES11
	    Required binaries: `/usr/bin/zypper`.  Supported features:
	    `installable`, `uninstallable`, `upgradeable`, `versionable`.

Now let's add a section to the **default.pp** file to install **apache**:

	elatov@kmac:~/test2/manifests$cat default.pp
	exec { "zypper update -y":
	  path => "/usr/bin",
	}
	
	package { "apache2":
	  ensure  => present,
	  require => Exec["zypper update -y"],
	}
	
	service { "apache2":
	  ensure  => "running",
	  require => Package["apache2"],
	}


Then when you re-**provision** the VM:

	elatov@kmac:~/test2$vagrant provision
	==> default: Running provisioner: puppet...
	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//Exec[zypper update -y]/returns: executed successfully
	==> default: Notice: /Stage[main]//Package[apache2]/ensure: created
	==> default: Notice: /Stage[main]//Service[apache2]/ensure: ensure changed 'stopped' to 'running'
	
If you want to see more information as to what puppet is doing, you can pass additional options to **puppet**. For example I added the following to the **VagrantFile**:

	puppet.options = "--verbose --debug"

and then I saw the following:

	elatov@kmac:~/test2$vagrant provision
	==> default: Running provisioner: puppet...
	==> default: Running Puppet with default.pp...
	==> default: Debug: Executing '/bin/rpm --version'
	==> default: Debug: Executing '/bin/rpm --version'
	==> default: Debug: Executing '/bin/rpm -ql rpm'
	==> default: Debug: Executing '/bin/rpm -ql rpm'
	==> default: Debug: Puppet::Type::Package::ProviderPacman: file /usr/bin/pacman does not exist
	==> default: Debug: Puppet::Type::Package::ProviderSun: file /usr/bin/pkginfo does not exist
	==> default: Debug: Puppet::Type::Package::ProviderAix: file /usr/bin/lslpp does not exist
	==> default: Debug: Puppet::Type::Package::ProviderDpkg: file /usr/bin/dpkg does not exist
	==> default: Debug: Puppet::Type::Package::ProviderHpux: file /usr/sbin/swinstall does not exist
	==> default: Debug: Puppet::Type::Package::ProviderPkgin: file pkgin does not exist
	==> default: Debug: Puppet::Type::Package::ProviderYum: file yum does not exist
	==> default: Debug: Puppet::Type::Package::ProviderPortage: file /usr/bin/emerge does not exist
	==> default: Debug: Puppet::Type::Package::ProviderPkg: file /usr/bin/pkg does not exist
	==> default: Debug: Puppet::Type::Package::ProviderOpenbsd: file pkg_info does not exist
	==> default: Debug: Puppet::Type::Package::ProviderFreebsd: file /usr/sbin/pkg_info does not exist
	==> default: Debug: Puppet::Type::Package::ProviderRug: file /usr/bin/rug does not exist
	==> default:
	==> default: Debug: Puppet::Type::Package::ProviderAptrpm: file apt-get does not exist
	==> default: Debug: Puppet::Type::Package::ProviderSunfreeware: file pkg-get does not exist
	==> default: Debug: Puppet::Type::Package::ProviderFink: file /sw/bin/fink does not exist
	==> default: Debug: Puppet::Type::Package::ProviderPorts: file /usr/local/sbin/portupgrade does not exist
	==> default: Debug: Puppet::Type::Package::ProviderPortupgrade: file /usr/local/sbin/portupgrade does not exist
	==> default: Debug: Puppet::Type::Package::ProviderOpkg: file opkg does not exist
	==> default: Debug: Puppet::Type::Package::ProviderUp2date: file /usr/sbin/up2date-nox does not exist
	==> default: Debug: Puppet::Type::Package::ProviderApt: file /usr/bin/apt-get does not exist
	==> default: Debug: Puppet::Type::Package::ProviderAptitude: file /usr/bin/aptitude does not exist
	==> default: Debug: Puppet::Type::Package::ProviderUrpmi: file urpmi does not exist
	==> default: Debug: Puppet::Type::Package::ProviderNim: file /usr/sbin/nimclient does not exist
	==> default: Debug: Puppet::Type::Service::ProviderDaemontools: file /usr/bin/svc does not exist
	==> default: Debug: Puppet::Type::Service::ProviderRunit: file /usr/bin/sv does not exist
	==> default: Debug: Puppet::Type::Service::ProviderOpenrc: file /sbin/rc-service does not exist
	==> default: Debug: Puppet::Type::Service::ProviderGentoo: file /sbin/rc-update does not exist
	==> default: Debug: Puppet::Type::Service::ProviderDebian: file /usr/sbin/update-rc.d does not exist
	==> default: Debug: Puppet::Type::Service::ProviderLaunchd: file /bin/launchctl does not exist
	==> default: Debug: Creating default schedules
	==> default: Debug: Failed to load library 'selinux' for feature 'selinux'
	==> default: Debug: Using settings: adding file resource 'confdir': 'File[/etc/puppet]{:path=>"/etc/puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'vardir': 'File[/var/lib/puppet]{:path=>"/var/lib/puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Puppet::Type::User::ProviderUser_role_add: file roleadd does not exist
	==> default: Debug: Failed to load library 'ldap' for feature 'ldap'
	==> default: Debug: Puppet::Type::User::ProviderLdap: feature ldap is missing
	==> default: Debug: Puppet::Type::User::ProviderPw: file pw does not exist
	==> default: Debug: Puppet::Type::User::ProviderDirectoryservice: file /usr/bin/dsimport does not exist
	==> default: Debug: /User[puppet]: Provider useradd does not support features libuser; not managing attribute forcelocal
	==> default: Debug: Failed to load library 'ldap' for feature 'ldap'
	==> default: Debug: Puppet::Type::Group::ProviderLdap: feature ldap is missing
	==> default: Debug: Puppet::Type::Group::ProviderPw: file pw does not exist
	==> default: Debug: Puppet::Type::Group::ProviderDirectoryservice: file /usr/bin/dscl does not exist
	==> default: Debug: /Group[puppet]: Provider groupadd does not support features libuser; not managing attribute forcelocal
	==> default: Debug: Using settings: adding file resource 'logdir': 'File[/var/log/puppet]{:path=>"/var/log/puppet", :mode=>"750", :owner=>"puppet", :group=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'statedir': 'File[/var/lib/puppet/state]{:path=>"/var/lib/puppet/state", :mode=>"1755", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'rundir': 'File[/var/run/puppet]{:path=>"/var/run/puppet", :mode=>"1777", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'libdir': 'File[/var/lib/puppet/lib]{:path=>"/var/lib/puppet/lib", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'certdir': 'File[/var/lib/puppet/ssl/certs]{:path=>"/var/lib/puppet/ssl/certs", :owner=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'ssldir': 'File[/var/lib/puppet/ssl]{:path=>"/var/lib/puppet/ssl", :mode=>"771", :owner=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'publickeydir': 'File[/var/lib/puppet/ssl/public_keys]{:path=>"/var/lib/puppet/ssl/public_keys", :owner=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'requestdir': 'File[/var/lib/puppet/ssl/certificate_requests]{:path=>"/var/lib/puppet/ssl/certificate_requests", :owner=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'privatekeydir': 'File[/var/lib/puppet/ssl/private_keys]{:path=>"/var/lib/puppet/ssl/private_keys", :mode=>"750", :owner=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'privatedir': 'File[/var/lib/puppet/ssl/private]{:path=>"/var/lib/puppet/ssl/private", :mode=>"750", :owner=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'statefile': 'File[/var/lib/puppet/state/state.yaml]{:path=>"/var/lib/puppet/state/state.yaml", :mode=>"660", :ensure=>:file, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'clientyamldir': 'File[/var/lib/puppet/client_yaml]{:path=>"/var/lib/puppet/client_yaml", :mode=>"750", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'client_datadir': 'File[/var/lib/puppet/client_data]{:path=>"/var/lib/puppet/client_data", :mode=>"750", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'clientbucketdir': 'File[/var/lib/puppet/clientbucket]{:path=>"/var/lib/puppet/clientbucket", :mode=>"750", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'lastrunfile': 'File[/var/lib/puppet/state/last_run_summary.yaml]{:path=>"/var/lib/puppet/state/last_run_summary.yaml", :mode=>"644", :ensure=>:file, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'lastrunreport': 'File[/var/lib/puppet/state/last_run_report.yaml]{:path=>"/var/lib/puppet/state/last_run_report.yaml", :mode=>"640", :ensure=>:file, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Using settings: adding file resource 'graphdir': 'File[/var/lib/puppet/state/graphs]{:path=>"/var/lib/puppet/state/graphs", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: /File[/var/lib/puppet/state]: Autorequiring File[/var/lib/puppet]
	==> default: Debug: /File[/var/lib/puppet/lib]: Autorequiring File[/var/lib/puppet]
	==> default: Debug: /File[/var/lib/puppet/ssl/certs]: Autorequiring File[/var/lib/puppet/ssl]
	==> default: Debug: /File[/var/lib/puppet/ssl]: Autorequiring File[/var/lib/puppet]
	==> default: Debug: /File[/var/lib/puppet/ssl/public_keys]: Autorequiring File[/var/lib/puppet/ssl]
	==> default: Debug: /File[/var/lib/puppet/ssl/certificate_requests]: Autorequiring File[/var/lib/puppet/ssl]
	==> default: Debug: /File[/var/lib/puppet/ssl/private_keys]: Autorequiring File[/var/lib/puppet/ssl]
	==> default: Debug: /File[/var/lib/puppet/ssl/private]: Autorequiring File[/var/lib/puppet/ssl]
	==> default: Debug: /File[/var/lib/puppet/state/state.yaml]: Autorequiring File[/var/lib/puppet/state]
	==> default: Debug: /File[/var/lib/puppet/client_yaml]: Autorequiring File[/var/lib/puppet]
	==> default: Debug: /File[/var/lib/puppet/client_data]: Autorequiring File[/var/lib/puppet]
	==> default: Debug: /File[/var/lib/puppet/clientbucket]: Autorequiring File[/var/lib/puppet]
	==> default: Debug: /File[/var/lib/puppet/state/last_run_summary.yaml]: Autorequiring File[/var/lib/puppet/state]
	==> default: Debug: /File[/var/lib/puppet/state/last_run_report.yaml]: Autorequiring File[/var/lib/puppet/state]
	==> default: Debug: /File[/var/lib/puppet/state/graphs]: Autorequiring File[/var/lib/puppet/state]
	==> default: Debug: Finishing transaction 33049200
	==> default: Debug: Loaded state in 0.01 seconds
	==> default: Debug: Loaded state in 0.00 seconds
	==> default: Info: Applying configuration version '1403541791'
	==> default: Debug: /Stage[main]//Package[apache2]/require: requires Exec[zypper update -y]
	==> default: Debug: /Stage[main]//Service[apache2]/require: requires Package[apache2]
	==> default: Debug: /Schedule[daily]: Skipping device resources because running on a host
	==> default: Debug: /Schedule[monthly]: Skipping device resources because running on a host
	==> default: Debug: /Schedule[hourly]: Skipping device resources because running on a host
	==> default: Debug: /Schedule[never]: Skipping device resources because running on a host
	==> default: Debug: /Schedule[weekly]: Skipping device resources because running on a host
	==> default: Debug: Exec[zypper update -y](provider=posix): Executing 'zypper update -y'
	==> default: Debug: Executing 'zypper update -y'
	==> default: Notice: /Stage[main]//Exec[zypper update -y]/returns: executed successfully
	==> default: Debug: /Stage[main]//Exec[zypper update -y]: The container Class[Main] will propagate my refresh event
	==> default: Debug: Prefetching zypper resources for package
	==> default: Debug: Executing '/bin/rpm --version'
	==> default: Debug: Executing '/bin/rpm -qa --nosignature --nodigest --qf '%{NAME} %|EPOCH?{%{EPOCH}}:{0}| %{VERSION} %{RELEASE} %{ARCH}
	==> default: ''
	==> default: Debug: Executing '/sbin/service apache2 status'
	==> default: Debug: /Schedule[puppet]: Skipping device resources because running on a host
	==> default: Debug: Class[Main]: The container Stage[main] will propagate my refresh event
	==> default: Debug: Finishing transaction 24728520
	==> default: Debug: Storing state
	==> default: Debug: Stored state in 0.07 seconds
	==> default: Notice: Finished catalog run in 0.81 seconds
	==> default: Debug: Using settings: adding file resource 'rrddir': 'File[/var/lib/puppet/rrd]{:path=>"/var/lib/puppet/rrd", :mode=>"750", :owner=>"puppet", :group=>"puppet", :ensure=>:directory, :loglevel=>:debug, :links=>:follow, :backup=>false}'
	==> default: Debug: Finishing transaction 33769460
	==> default: Debug: Received report to process from linux-mjbf.bdr.symplified.net
	==> default: Debug: Processing report from linux-mjbf.bdr.symplified.net with processor Puppet::Reports::Store
	
To confirm that it worked, you can ssh to the VM and make sure it was installed and apache is actually running:

	elatov@kmac:~/test2$vagrant ssh
	Last login: Mon Jun 23 10:46:28 2014 from 10.0.2.2
	Have a lot of fun...
	vagrant@linux-mjbf:~> tail -1 /var/log/zypp/history
	2014-06-23 10:34:13|install|apache2-prefork|2.4.6-6.23.1|x86_64||openSUSE_13.1_Updates|dcc58e42a75bc78eb9e67d28cfa5bd05b1a3f85bd991737ab7fd6751323e2c33|
	vagrant@linux-mjbf:~> ps -eaf | grep apache | grep -v grep | tail -1
	wwwrun    3637  3616  0 10:37 ?        00:00:00 /usr/sbin/httpd2-prefork -f /etc/apache2/httpd.conf -D SYSTEMD -DFOREGROUND -k start