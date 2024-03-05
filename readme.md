# hosting a k8s cluster at home

I've been spending ~$48/mo on two Linodes (each 1 core, 2GB RAM, 50GB storage), 
NodeBalancers, s3, and block storage.

My software should be reproducible on any k8s cluster.

This is my attempt at doing so.

## dev-dependencies

- just
- ansible (pip/netaddr/paramiko)
- k0sctl (go)
- terraform
- helm

## hardware

On my home network I'm running VyOS as a programmable router/firewall.

I've got three `Orange Pi 5`s with 256GB of NVMe storage and 8-16GB of RAM.
In 7-8 months, it will become cost-saving to self-host,
and I will have significantly more capable systems.

In addition to that, I pay for a very cheap VM from BuyVM to act as a forward proxy/port redirector. 


|      alias | role                | MAC address       |
|-----------:|---------------------|:------------------|
|    gateway | firewall            | --                |
|      proxy | proxy               | --                |
|      aster | worker              | c6:f4:bd:8a:f0:7e |
| bernadette | worker              | 32:2d:6a:8f:02:d3 |
|        nas | controller + worker | 04:7c:16:be:3a:e9 |


## machine configuration

### workers

I brought the preconfigured SD card to each machine, booted them up, 
logged in via SSH (thanks to that image having a constant mDNS name),
and ran a justfile that copies the OS over to the NVMe and sets a new hostname.

Further configuration is handled through Ansible.

Relevant files are in `./supplements`,
and can be written directly into the SD card's filesystem or copied to a USB stick.

### gateway 

I installed VyOS on my firewall and performed initial setup with the 
[quick start guide](https://docs.vyos.io/en/latest/quick-start.html), 
including setting up an SSH key and disabling password authentication.

Once the network was reachable with sshd running, 
further configuration can be handled with a config file deployed through Ansible.

### proxy

The proxy server runs nginx as a docker container in host network mode, 
as well as ddclient (actually inadyn).
The nginx.config is updated up to once a minute from a pod running in k8s, 
and redirects ports based on the ingress controller.

# environment/setup

Setting up a new machine is pretty simple. Ansible needs the .vault_pass file, which is kept elsewhere.
`just kubeconfig` to grab the kubeconfig from k0sctl.

Terraform needs some env vars set up, too. Idk, go figure that out from the var files.

# TODO:

- compile config.boot.j2 here, upload to vyos, and run a load command instead of using the vyos_config module, which maintains extraneous state.
- in config.boot.j2, turn hosts, ports and subdomains into lists instead of named items
- VPN for LAN access. ns.agency?
