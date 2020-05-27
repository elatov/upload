Use the **stdlib** to modify configuration files. So on the guest OS install the module:

	vagrant@linux-mjbf:~> sudo puppet module install puppetlabs-stdlib
	Notice: Preparing to install into /etc/puppet/modules ...
	Notice: Created target directory /etc/puppet/modules
	Notice: Downloading from https://forge.puppetlabs.com ...
	Notice: Installing -- do not interrupt ...
	/etc/puppet/modules
	└── puppetlabs-stdlib (v4.2.2)


Now my goal was to modify the wordpress configuration file, to go from this:

	define('DB_NAME', 'database_name_here');
	define('DB_USER', 'username_here');
	define('DB_PASSWORD', 'password_here');
	define('DB_HOST', 'localhost');

To this:

	define('DB_NAME', 'wordpress_db');
	define('DB_USER', 'wordpress_user');
	define('DB_PASSWORD', 'wordpress');
	define('DB_HOST', '192.168.33.2');


So then we can create a puppet file with the following:

	exec { "copy_def_config":
	        command => "/usr/bin/cp ${install_dir}/wp-config-sample.php ${install_dir}/wp-config.php",
	        creates => "${install_dir}/wp-config.php",
	        require => File["${install_dir}/wp-config-sample.php"],
	} ->
	file_line { 'db_name_line':
	  path  => "${install_dir}/wp-config.php",
	  line  => "define('DB_NAME', 'wordpress_db');",
	  match => "^define\\('DB_NAME*",
	} ->
	file_line { 'db_user_line':
	  path  => "${install_dir}/wp-config.php",
	  line  => "define('DB_USER', 'wordpress_user');",
	  match => "^define\\('DB_USER*",
	} ->
	file_line { 'db_password_line':
	  path  => "${install_dir}/wp-config.php",
	  line  => "define('DB_PASSWORD', 'wordpress');",
	  match => "^define\\('DB_PASSWORD*",
	} ->
	file_line { 'db_host_line':
	  path  => "${install_dir}/wp-config.php",
	    line  => "define('DB_HOST', '192.168.33.2');",
	  match => "^define\\('DB_HOST*",
	} ~>
	exec { 'Change ownership':
	        command     => "sudo chown -R wwwrun:www ${install_dir}",
	        require => Exec["Extract wordpress"],
	        refreshonly => true,
	}
	
Then applying the manifest, you will see the following:


	==> default: Running Puppet with default.pp...
	==> default: Notice: /Stage[main]//File_line[db_name_line]/ensure: created
	==> default: Notice: /Stage[main]//File_line[db_user_line]/ensure: created
	==> default: Notice: /Stage[main]//File_line[db_password_line]/ensure: created
	==> default: Notice: /Stage[main]//File_line[db_host_line]/ensure: created
	==> default: Notice: /Stage[main]//Exec[Change ownership]: Triggered 'refresh' from 1 events