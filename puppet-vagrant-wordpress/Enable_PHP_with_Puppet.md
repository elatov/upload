Here is puppet to install and enable the php module for apache:


	package { "apache2":
	        ensure  => present,
	        require => Exec["system-update"],
	}
	
	package { "apache2-mod_php5":
	        ensure  => present,
	        require => Exec["system-update"],
	}
	
	service { "apache2":
	        ensure  => "running",
	        enable => "true",
	        require => Package["apache2"],
	}
	exec { "enable-php-module":
	        command => "sudo a2enmod php5",
	        unless => "grep php5 /etc/sysconfig/apache2",
	        require => Package["apache2-mod_php5"],
	        notify => Service["apache2"],
	}
	
Applying that manifest, will show you the following:

	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//Exec[enable-php-module]/returns: executed successfully
	==> default: Notice: /Stage[main]//Service[apache2]: Triggered 'refresh' from 1 events