# hosting a k8s cluster at home

I've been spending ~$48/mo on two Linodes (each 1 core, 2GB RAM, 50GB storage), 
NodeBalancers, s3, and block storage.

My software should be reproducible on any k8s cluster.

This is my attempt at doing so.

## dev-dependencies

- just
- pkl
- ansible (pip/netaddr/paramiko)
- k0sctl (go)
- terraform
- helm

## hardware

On my home network I'm running VyOS as a programmable router/firewall.

I've got three `Orange Pi 5`s with 256GB of NVMe storage and 8-16GB of RAM,
as well as a cheap Ryzen 5 4600G based desktop acting as a controller/NAS.

In addition to that, I pay for a very cheap VM from BuyVM to act as a forward proxy/port redirector. 


|   alias | role                | LAN/eth MAC address |
|--------:|---------------------|:--------------------|
| gateway | firewall            | --                  |
|   proxy | proxy               | --                  |
|     nas | controller + worker | 04:7c:16:be:3a:e9   |
|   aster | worker              | fe:b5:89:c4:4f:a7   |
|    bert | worker              | f2:0b:1d:89:90:2e   |
| charles | worker              | 2e:ca:26:38:5d:df   |


## machine configuration

### cluster

For ansible and k0s to set up the cluster, each machine just needs SSH access.
See the makefile in `./supplements`, used for setting up users and ssh keys.
Some manual setup is needed for disabling root login, password login, and whatnot.

### gateway 

I installed VyOS on my firewall and performed initial setup with the 
[quick start guide](https://docs.vyos.io/en/latest/quick-start.html), 
including setting up an SSH key and disabling password authentication.

Once the network was reachable with sshd running, 
further configuration can be handled with a config file deployed through Ansible.

### proxy

The proxy server runs nginx as a docker container in host network mode.

The nginx.config is updated up to once a minute from a pod running in k8s, 
and redirects ports based on the ingress controller.

# environment/setup

Setting up a new machine is pretty simple. Ansible needs the .vault_pass file, which is kept elsewhere.
`just kubeconfig` to grab the kubeconfig from k0sctl.

Terraform needs some env vars set up, too. Idk, go figure that out from the var files.

Also, watch out for things like firewalld on Fedora.

```/provisioning
just network
just init-cluster-hardware
just create-cluster # can also be used to update cluster, but might not be entirely consistent for some values
```

then for each dir in `/terraform`, init and apply modules.

# TODO:

- compile config.boot.j2 here, upload to vyos, and run a load command instead of using the vyos_config module, which maintains extraneous state.
- VPN for LAN access. ns.agency?


- opi 5: sudo apt install 
- linux-image-edge-rockchip-rk3588
- linux-dtb-edge-rockchip-rk3588
- linux-u-boot-orangepi5-edge