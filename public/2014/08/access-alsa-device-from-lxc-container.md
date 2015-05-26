Access ALSA device from LXC container
=====================================
August 20, 2014

In LXC configuration file, allow cgroup access to `/dev/snd` and bind
mount it:

```
# Apparently, cgroup for `/dev/snd`
lxc.cgroup.devices.allow = c 116:* rwm

lxc.mount.entry = /dev/snd /var/lib/lxc/music/rootfs/dev/snd none bind 0 0
```

Both host and child must have ALSA installed.
