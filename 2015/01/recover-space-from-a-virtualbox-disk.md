# Recover space from a VirtualBox disk
January 18, 2015

When you write large files in a dynamically sized  VirtualBox disk,
deleting them won't help recovering the space at host level. The files
will more likely still be on the filesystem, even if marked as free
space.

To shrink a VirtualBox disk after removing large files, just zero out
the rest of the drive, before asking VirtualBox to compact the disk:

On the guest:

```sh
dd if=/dev/zero of=junk # Will fail with disk full error
sync
rm junk
```

On the host:

```sh
find ~/VirtualBox\ VMs -name '*.vdi' -exec VBoxManage modifyhd --compact  {} \;
```

Here, I choose to compact all the disks, but you can just apply the
`-exec` command to a single one.
