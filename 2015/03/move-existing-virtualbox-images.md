# Move existing VirtualBox images
March 27, 2015

I ran out of disk space in my home directory because VirtualBox images
were taking too much space. I wanted to move them to my data partition
that has way more space, but I could not find a way to do this with the
VirtualBox GUI.

However, while I found no documentation on the subject, it's really easy
to do by moving the images, and updating the VirtualBox configuration
file accordingly:


```sh
mv /home/val/VirtualBox\ VMs/* /data/virtualbox
```

Then edit the VirtualBox configuration file, depending on the version
and system, `~/.config/VirtualBox/VirtualBox.xml` or
`~/.VirtualBox/VirtualBox.xml`, to replace the old path with the new
path:

```sh
sed -i 's,/home/val/VirtualBox VMs,/data/virtualbox,' ~/.config/VirtualBox/VirtualBox.xml
```

Restart VirtualBox, and everything should work, but the images are now
on the other partition!
