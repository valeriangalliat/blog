# Run macOS inside Docker on Linux, with Wayland
April 13, 2022

This is gonna be a short one. There's this fucking fantastic software
called [Docker-OSX](https://github.com/sickcodes/Docker-OSX) that
lets you run a macOS VM on Linux out of the box, just like that. ✨

Running macOS on a non-Apple hardware is already
[not a](https://www.codejam.info/2019/03/macos-high-sierra-msi-h110m-pro-d-skylake-nvidia-pascal.html)
[trivial task](https://www.codejam.info/2021/11/yearly-hackintosh-upgrade-macos-monterey-with-opencore.html),
even though [OpenCore](https://github.com/acidanthera/OpenCorePkg) and
the (also fucking fantastic) [Dortania guide](https://dortania.github.io/OpenCore-Install-Guide/)
help greatly. Let alone running it inside a VM.

Docker-OSX is based on [OSX-KVM](https://github.com/kholia/osx-kvm) as
well as [KVM-OpenCore](https://github.com/thenickdude/KVM-Opencore/),
and provides a Docker container that's preconfigured to run the macOS
installer of your choice inside a KVM virtual machine that's already
set up to support macOS.

With some Docker volume mounts magic, it can show the KVM window
directly on your X11 display, despite you not installing KVM on your
main system and configuring anything. Sweet.

The commands to run various macOS versions are directly [in the readme](https://github.com/sickcodes/Docker-OSX#quick-start-docker-osx)
and work out of the box! Example for Monterey:

```sh
docker run -it \
    --device /dev/kvm \
    -p 50922:10022 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -e GENERATE_UNIQUE=true \
    -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom.plist' \
    sickcodes/docker-osx:monterey
```

## Making it work on Wayland

I recently moved to Wayland, so setting `DISPLAY=:0.0` and mount binding
`/tmp/.X11-unix` is not gonna do much. 😬

At the time of writing, there's no official instructions in the readme
to run with Wayland, but the task turned out to be fairly easy!

Luckily I'm not the first one to try to do that, and there's already two
[open](https://github.com/sickcodes/Docker-OSX/issues/410)
[issues](https://github.com/sickcodes/Docker-OSX/issues/419) on the
topic! The second one in particular contains a
[solution](https://github.com/sickcodes/Docker-OSX/issues/419#issuecomment-1011401905),
essentially replacing the X11-specific volume and environment variable
by Wayland equivalents (which I would definitely not have guessed easily 😂).

Once adapted for Monterey, the command is the following:

```sh
docker run -it \
    --device /dev/kvm \
    -p 50922:10022 \
    -e XDG_RUNTIME_DIR=/tmp \
    -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:/tmp/$WAYLAND_DISPLAY  \
    -e GENERATE_UNIQUE=true \
    -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom.plist' \
    sickcodes/docker-osx:monterey
```

The original comment specified a number of extra environment variables
but they didn't appear to be needed for me.

And that's it! Happy hacking on macOS in a VM! 🎉
