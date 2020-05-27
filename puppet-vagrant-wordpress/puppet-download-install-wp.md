Installing wordpress with puppet, here is the file, I had created:

	elatov@kmac:~/test2$cat manifests/default.pp
	exec { "system-update":
	  command => "zypper update -y",
	  path => "/usr/bin",
	}
	
	package { "wget":
	  ensure  => present,
	}
	
	package { "apache2":
	  ensure  => present,
	  require => Exec["system-update"],
	}
	
	service { "apache2":
	  ensure  => "running",
	  require => Package["apache2"],
	}
	
	$install_dir = '/srv/www/htdocs/wp'
	
	file { $install_dir:
		ensure  => directory,
		recurse => true,
	}
	
	exec { 'Download wordpress':
	    command => "wget http://wordpress.org/latest.tar.gz -O /tmp/wp.tar.gz",
	    path => "/usr/local/bin:/bin:/usr/bin",
	    creates => "/tmp/wp.tar.gz",
	    require => [ File[$install_dir], Package["wget"] ],
	}
	
	exec { 'Extract wordpress':
	    command => "sudo tar zxvf /tmp/wp.tar.gz --strip-components=1 -C ${install_dir}",
	    path => "/usr/local/bin:/bin:/usr/bin",
	    creates => "${install_dir}/index.php",
	    require => Exec["Download wordpress"],
	}
	
	exec { 'Change ownership':
		command     => "chown -R wwwrun:www ${install_dir}",
		path => "/usr/local/bin:/bin:/usr/bin",
		refreshonly => true,
		require => Exec["Extract wordpress"],
	}
	
Then running that, I got the following results:

	elatov@kmac:~/test2$vagrant provision
	==> default: Running provisioner: puppet...
	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//Package[wget]/ensure: created
	==> default: Notice: /Stage[main]//Exec[Download wordpress]/returns: executed successfully
	==> default: Notice: /Stage[main]//Exec[Extract wordpress]/returns: executed successfully
	==> default: Notice: /Stage[main]//Exec[system-update]/returns: executed successfully
	==> default: Notice: /Stage[main]//Exec[Change ownership]/returns: executed successfully
	==> default: Notice: Finished catalog run in 6.52 seconds

Then checking the results:

	elatov@kmac:~/test2$vagrant ssh
	Last login: Mon Jun 23 12:19:54 2014 from 10.0.2.2
	Have a lot of fun...
	vagrant@linux-mjbf:~> file /tmp/wp.tar.gz
	/tmp/wp.tar.gz: gzip compressed data, from Unix, last modified: Thu May  8 11:45:14 2014
	vagrant@linux-mjbf:~> ls /srv/www/htdocs/wp/
	index.php	 wp-blog-header.php    wp-includes	  wp-settings.php
	license.txt	 wp-comments-post.php  wp-links-opml.php  wp-signup.php
	readme.html	 wp-config-sample.php  wp-load.php	  wp-trackback.php
	wp-activate.php  wp-content	       wp-login.php	  xmlrpc.php
	wp-admin	 wp-cron.php	       wp-mail.php
	vagrant@linux-mjbf:~> ls -ld /srv/www/htdocs/wp/
	drwxr-xr-x 5 wwwrun www 4096 Jun 23 13:05 /srv/www/htdocs/wp/
	
