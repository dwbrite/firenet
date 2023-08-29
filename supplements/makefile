.PHONY: preinstall hostname-machine dd cleanup

preinstall: devin
install-machine: hostname-machine dd cleanup

devin:
	sudo adduser dewbrite
	sudo usermod -aG sudo dewbrite
	sudo su dwbrite
	mkdir ~/.ssh
	chmod 700 ~/.ssh
	cat ./id_rsa.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys
	sudo passwd -l ubuntu

hostname-machine:
	sudo hostnamectl hostname $(MACHINE)
	- avahi-set-host-name $(MACHINE)
	sudo rm /etc/machine-id
	sudo systemd-machine-id-setup

dd:
	sudo bash -c 'cat /dev/mmcblk0 >> /dev/nvme0n1'
	sudo e2fsck -fy /dev/nvme0n1p2
	sudo resize2fs  /dev/nvme0n1p2 60G
	yes | sudo parted /dev/nvme0n1 ---pretend-input-tty resizepart 2 64G
	sudo resize2fs  /dev/nvme0n1p2
	sudo parted /dev/nvme0n1 mkpart primary ext4 64GiB 100%
	sudo mkfs.ext4 /dev/nvme0n1p3

cleanup:
	sleep 5
	sudo hostnamectl hostname clementine-proto
	- avahi-set-host-name clementine-proto
