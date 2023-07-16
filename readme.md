# hosting a k8s cluster at home

I've been spending ~$48/mo on two Linodes (each 1 core, 2GB RAM, 50GB storage), 
NodeBalancers, s3, and block storage.

My software should be reproducible on any k8s cluster.

This is my attempt at doing so.

## dev-dependencies

- just
- ansible (pip/netaddr)
- k0sctl (go)
- terraform

## hardware

I've got three `Orange Pi 5`s with 256GB of NVMe storage and 8-16GB of RAM.
In 7-8 months, it will become cost-saving to self-host,
and I will have significantly more capable systems.

In addition to that, I have an x86 firewall running VyOS, 
which also acts as the k0s controller. Mostly because 
k0s does not support running aarch64 controllers. Yet.


|      alias | role                  | MAC address       |
|-----------:|-----------------------|:------------------|
|    gateway | firewall + controller | --                |
|      aster | worker                | c6:f4:bd:8a:f0:7e |
| bernadette | worker                | 32:2d:6a:8f:02:d3 |
|    charlie | worker                | 7a:fc:cc:12:3c:bc |


## machine configuration

### workers

To boot from an SSD on the Orange Pi 5s, you need to update the SPI_FLASH bootloader.
I did this manually with the Orange Pi debian images.

Following that, I installed RebornOS onto an SD card on one of the machines.
Then I configured ssh and just.

I brought the preconfigured SD card to each machine, booted them up, 
logged in via SSH (thanks to that image having a constant mDNS name),
and ran a justfile that copies the OS over to the NVMe and sets a new hostname.

Further configuration is handled through Ansible.

---

Relevant files are in the `./supplements` directory,
and can be written directly into the SD card's filesystem or copied to a USB stick.

### gateway 

I installed VyOS on my firewall and performed initial setup with the 
[quick start guide](https://docs.vyos.io/en/latest/quick-start.html), 
including setting up an SSH key and disabling password authentication.

Once the network was reachable with sshd running, 
further configuration can be handled with a config file deployed through Ansible.
