# Installing NixOS on a Kimsufi
December 24, 2015

**Sidenote:** yes, I'm absolutely doing this on a December 24.

## Introduction

I recently obtained a [Kimsufi](https://www.kimsufi.com/) server[^1] and
wanted to install NixOS on it. Though the web installation wizard
doesn't know about NixOS, thus requiring some more manual steps to
install it.

This blog post is an (up-to-date) mix of [How to install NixOS from
Linux][nixos-from-linux] and
[Install NixOS on a So You Start Dedicated server][nixos-so-you-start]
articles.

[nixos-from-linux]: https://nixos.org/wiki/How_to_install_NixOS_from_Linux
[nixos-so-you-start]: http://aborsu.github.io/2015/09/26/Install%20NixOS%20on%20So%20You%20Start%20dedicated%20server/

## Get the network info

I started from an Arch Linux installation (available on the web
installation wizard). If you have another system running, you can skip
this step.

The idea is just to SSH into a preconfigured system to get the network
information, namely the hostname, IPv4 and IPv6 adresses, netmasks and
gateways, and optionally DNS servers.

You can find the hostname in the standard `/etc/hostname`, and IP
information in `/root/.ovhrc` and `/etc/netctl/ovh_net_eth0`.

```sh
# /root/.ovhrc
DNS_IP="{{ IPV4_DNS }}"
DNS_IPV6="{{ IPV6_DNS }}"
IPV6ADDR="{{ IPV6_ADDR }}"
IPV6GW="{{ IPV6_GW }}"
IPV6NETMASK="{{ IPV6_NETMASK }}"
SERVERNAME="{{ HOSTNAME }}.whatever.eu"
```

```sh
# /etc/netctl/ovh_net_eth0
Address=('{{ IPV4_ADDR }}/{{ IPV4_NETMASK }}')
Gateway=('{{ IPV4_GW }}')
DNS=('{{ IPV4_DNS }}')
Address6=('{{ IPV6_ADDR }}/{{ IPV6_NETMASK }}')
IPCustom=('-6 route add {{ IPV6_GW }} dev eth0' '-6 route add default via {{ IPV6_GW }}
```

You will need those when creating your NixOS configuration.

## Fake boot in NixOS ISO

We cannot specify a custom ISO to boot in, so we need to boot in rescue
mode and replicate the NixOS ISO system in order to do the
[regular installation](#regular-installation) steps.

After restarting in rescue mode, you'll receive a mail with the SSH
credentials. Once there, execute the following steps:

### Predict the network interface name

In rescue mode the public network interface is `eth0` but in NixOS, with
systemd, it's a different name, and you'll need to explicitly specify it
for the network configuration. For this, run the following command:

```sh
udevadm test-builtin net_id /sys/class/net/eth0 2> /dev/null
```

Which will output:

```sh
ID_NET_NAME_PATH={{ NETIF }}
```

### Format the disk (optional)

While this step is usually done in the
[regular installation](#regular-installation) procedure, we need to do
this before because faking the NixOS ISO system requires more space than
available in rescue mode (at least in case of my instance), so I need to
prepare a small (2GB) partition for this.

```sh
fdisk /dev/sda
```

Personally I made 4 partitions, one of 30GB for the system, one for the
home, and at the end 2GB for swap, and 2GB to extract NixOS.

```sh
mkfs.ext4 -L nixos /dev/sda1
mkfs.ext4 -L home /dev/sda2
mkswap -L swap /dev/sda3
mkfs.ext4 -L nixos-rescue /dev/sda4
```

The following commands assume this layout, obviously tweak them
for your own needs.

### Prepare the working directories

We create an `image` directory to mount the installation ISO in, and a
`rescue` directory to mount the 2GB `nixos-rescue` partition and
replicate the ISO system in.

```sh
mkdir image rescue
mount /dev/disk/by-label/nixos-rescue rescue
mkdir rescue/nix
```

### Get the ISO and mount it

Get the ISO URL of the NixOS release you want to install, see the
[download page](http://nixos.org/nixos/download.html).

In my case I fetched the latest unstable at this date:

```sh
wget 'https://nixos.org/releases/nixos/unstable/nixos-16.03pre73316.93d8671/nixos-minimal-16.03pre73316.93d8671-x86_64-linux.iso'
mount -o loop nixos-minimal-16.03pre73316.93d8671-x86_64-linux.iso image
```

### Extract the store

To extract the store from the ISO to the rescue system, we need to get
the `squashfs-tools` package, then extract it:

```sh
apt-get install squashfs-tools
unsquashfs -d rescue/nix/store image/nix-store.squashfs '*'
```

### Populate the system

We then recreate the needed
[FHS](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)
entries and mount bind or copy whatever is needed from the host system:

```sh
cd rescue
mkdir -p etc dev proc sys
mount --bind /dev dev
mount --bind /proc proc
mount --bind /sys sys
```

Also take note of the content of `/etc/resolv.conf` to manually copy it
after `chroot`.

### `chroot` in the installation system

First need to find the right path for `init` and `bash`:

```sh
INIT=$(find . -type f -path '*nixos*/init')
BASH=$(find . -type f -path '*/bin/bash' | tail -n 1)

# See <https://discourse.nixos.org/t/nixos-on-ovh-kimsufi-cloning-builder-process-operation-not-permitted/1494/2>
find . -type f -path '*-nix.conf' | xargs sed -i 's/sandbox = true/sandbox = false/'
```

Then modify the init script to execute `bash` instead of `systemd`:

```sh
sed -i "s,exec systemd,exec /$BASH," "$INIT"
```

Now ready to `chroot`:

```sh
chroot . /$INIT
```

Just after, restore the `/etc/resolv.conf`.

## Regular installation

You can now install your system as if you were in the installation ISO:

```sh
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/home
mount /dev/disk/by-label/home /mnt/home
swapon /dev/disk/by-label/swap
nixos-generate-config --root /mnt
```

Then edit the configuration to reflect the OVH network settings, plus
usual stuff like boot loader, locale, timezone, users:

```sh
nix-env -i vim
vim /mnt/etc/nixos/configuration.nix
```

```nix
{ config, pkgs, ... }:

{
  # ...

  networking = {
    hostName = "{{ HOSTNAME }}";

    interfaces.{{ NETIF }} = {
      ip4 = [ { address = "{{ IPV4_ADDR }}"; prefixLength = {{ IPV4_NETMASK }}; } ];
      ip6 = [ { address = "{{ IPV6_ADDR }}"; prefixLength = {{ IPV6_NETMASK }}; } ];
    };

    defaultGateway = "{{ IPV4_GW }}";
    defaultGateway6 = "{{ IPV6_GW }}";

    nameservers = [ "{{ IPV4_DNS }}", "{{ IPV6_DNS }}" ];
  };

  # ...
}
```

I like to have those settings in an external file like
`/etc/nixos/ovh-configuration.nix` and add it to the `imports` list.

You're then ready to install the system:

```sh
nixos-install
```

If you want to execute more commands in your new system, like setting
passwords for new users:

```sh
nixos-install --chroot
```

Then you can unmount everything and exit:

```sh
umount -R /mnt
exit
```

## Final boot

From the management panel, define the hard disk as default boot device,
and reboot the system. You should be able to SSH with the user/password
you created previously.

## Troubleshooting

If your server doesn't go up, you can't connect, or whatever, boot back
in rescue mode, and look what happened in the system logs with:

```sh
mount /dev/disk/by-label/nixos /mnt
journalctl -D /mnt/var/log/journal
```

[^1]: Because I moved from France (where I have a
[home server](../../2014/10/low-consumption-home-server.md)) to
Quebec, and here we have a bandwidth consumption limit, and I don't feel
like hosting a home server behind a limited connection, especially when
sharing this connection with roommates! Hence the investment in renting
a dedicated server.
