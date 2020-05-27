Shutdown a VM for later use:

	elatov@kmac:~/new_vm$vagrant halt
	==> default: Attempting graceful shutdown of VM...
	
Remove the VM and disk associated with the VM:

	elatov@kmac:~/new_vm$vagrant destroy
	    default: Are you sure you want to destroy the 'default' VM? [y/N] y
	==> default: Destroying VM and associated drives...