# Static DHCP server on Arch Linux in 2021, two ways
November 26, 2021

Turns out it's 2021 and configuring a static server on at least some
Linux flavours isn't as easy as editing `/etc/resolv.conf` anymore, at
least if you want it to persist across reboots.

Depending on your network stack, I'll suggest two ways, one might work
for you, both work in my case.

In `/etc/resolvconf.conf`, add the following:

```
name_servers="1.1.1.1 1.0.0.1"
```

Or in `/etc/dhcpcd.conf`, add the following:

```
static domain_name_servers=1.1.1.1 1.0.0.1
```

Obviously replace `1.1.1.1` and `1.0.0.1` by the DNS servers of you
choosing.

But that being said, as far as I'm concerned, I went with the third
option which is to configure it at the router level! This way every
device that connects to it benefits from this configuration if they
don't override it.
