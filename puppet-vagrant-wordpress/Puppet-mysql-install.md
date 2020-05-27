Now let's move on to the db machine. To start out with I had this very simple puppet script:

	### Global setttings
	Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
	
	exec { "system-update":
	        command => "zypper update -y",
	        onlyif => "test $(facter uptime_seconds) -lt 300",
	}
	
	package { "wget":
	        ensure  => present,
	}
	package { "mysql-community-server":
	        ensure  => present,
	        require => Exec["system-update"],
	}
	
	service { "mysql":
	        ensure  => "running",
	        enable => "true",
	        require => Package["mysql-community-server"],
	}

Then applying that to brand new vagrant box:

	==> default: Running provisioner: puppet...
	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//Exec[system-update]/returns: executed successfully
	==> default: Notice: /Stage[main]//Package[mysql-community-server]/ensure: created
	==> default: Notice: /Stage[main]//Service[mysql]/ensure: ensure changed 'stopped' to 'running'