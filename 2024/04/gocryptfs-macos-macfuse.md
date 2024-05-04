---
tweet: https://twitter.com/valeriangalliat/status/1784030029187588316
---

# gocryptfs on macOS (with and without macFUSE)
Doing FUSE stuff on a Mac  
April 26, 2024

In this post I'm taking gocryptfs as an example because that's what I
use to encrypt my [offsite backups](offsite-backup-sync.md), but this
can probably be applied to doing anything FUSE-related on a Mac.

## gocryptfs on macOS

Using gocryptfs on macOS requires [macFUSE](https://osxfuse.github.io/).
macFUSE (previously known as [OSXFUSE](https://web.archive.org/web/20130710220229/https://osxfuse.github.io/)
(previously known as [MacFUSE](https://web.archive.org/web/20130704045540/http://code.google.com/p/macfuse/)
lol TIL)) is an awesome project that allows to mount
[FUSE](https://www.kernel.org/doc/html/next/filesystems/fuse.html)
filesystems on macOS.

All it takes is:

```sh
brew --cask install macfuse

# Do the reboot dance to allow the kernel extension (see "concerns" below)

brew install gromgit/fuse/gocryptfs-mac

# Not needed but might as well have SSHFS around too
brew install gromgit/fuse/sshfs-mac
```

<div class="note">

**Note:** gocryptfs and SSHFS can't be installed from Homebrew's main
registry anymore [because](https://github.com/Homebrew/homebrew-core/pull/74812#issuecomment-826895526)
they depend on macFUSE, which is not open-source.

This is why the above command installs from [this repository](https://github.com/gromgit/homebrew-fuse),
which hosts the Homebrew formulas that depend on FUSE that were dropped
from Homebrew.

</div>

## Concerns about macFUSE

Sadly, macFUSE is not open-source. But at least it's been updated
regularly for over 10 years, and keeps supporting the latest macOS
versions, so as long as this stays the case, I don't mind using it.

That said, depending on macFUSE for a process as critical as my [offsite backups](offsite-backup-sync.md)
means that I will need to wait for it to support a new macOS version
before I deem to upgrade. Because it's a kernel extension, it's
not necessarily as easy to upgrade as other userland programs.

The other problem is that Apple [deprecated kernel extensions](https://developer.apple.com/support/kernel-extensions/)
in 2020 with macOS Catalina (although they still work up to this date on
later versions). This is tracked in [this macFUSE issue](https://github.com/osxfuse/osxfuse/issues/987)
but at the time of writing, Apple doesn't provide APIs that allow to
implement macFUSE outside of a (now deprecated) kernel extension.

On top of that, going with the deprecation, Apple made it
[annoying](https://github.com/osxfuse/osxfuse/issues/814)
to install kernel extensions on ARM Macs, by having to reboot in
recovery and enabling "reduced security" mode (which is now [required](https://support.apple.com/en-ca/guide/security/sec7d92dc49f/web)
for kernel extensions).

While macFUSE works now, and have been working for many years after the
original deprecation of kernel extensions by Apple, its future is still
somewhat unclear.

In future versions, will macOS drop some the APIs that macFUSE depend
on, without providing viable alternatives? Or will they entirely block
kernel extensions? And in the event they do provide viable alternative
APIs, how long will it take for macFUSE to support that new version?

Otherwise, is any of the alternatives like
[FUSE-T](https://www.fuse-t.org/) gonna be solid enough by then? And
more importantly, is gocryptfs gonna work with those alternatives?
Actually, it won't, because right now
[go-fuse](https://github.com/hanwen/go-fuse) depends explicitly on
macFUSE.

So, I wasn't ready to commit to that setup without having a somewhat
viable fallback.

## gocryptfs on macOS without macFUSE


While FUSE, as we saw, is a bit of a challenge on macOS, it's perfectly
fine on Linux. gocryptfs and FUSE on Linux are not going anywhere.

Now, [Lima](https://github.com/lima-vm/lima) is a pretty sweet way to
run a Linux VM on macOS. Similarly to [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)
on Windows, Lima can drop you in a Linux shell on your Mac, with
transparent access to your files.

This means you can easily install gocryptfs in that Lima environment,
and use it there. Assuming I want to get an encrypted mount of my home
directory (`~`):

```sh
brew install lima

limactl start

lima sudo apt install gocryptfs

# Init in a temp dir because Lima can't write to the host filesystem
lima gocryptfs -init -reverse /tmp/lima

# From the host move the config file in the right place
mv /tmp/lima/.gocryptfs.reverse.conf ~

lima mkdir -p /tmp/encrypted
lima gocryptfs -reverse ~ /tmp/encrypted
lima rsync --archive /tmp/encrypted "$DESTINATION"
```

<div class="note">

**Note:** Depending on how you connect to `$DESTINATION`, you may want to
copy/link your SSH config and keys inside the Linux home of the VM
user. For example:

```sh
lima ln -s ~/.ssh/{config,id_ed25519*} "$(lima sh -c 'echo $HOME')/.ssh"
```

</div>

## Decrypting remote files

We can as easily do the opposite: use SSHFS to mount the remote
encrypted directory locally, then use gocryptfs to decrypt it and access
the files transparently.

```sh
lima sudo apt install sshfs

lima mkdir -p /tmp/encrypted /tmp/decrypted
sshfs -o idmap=user "$DESTINATION" /tmp/encrypted
gocryptfs /tmp/encrypted /tmp/decrypted
```

At that point we can browse the decrypted tree from the Lima shell,
however we can't access it from the host.

## Accessing decrypted files from the host

If Lima can access files from the host, why can't the host access files
from Lima?

Well, it comes down again to the ability to us FUSE. In order to access
host files, Lima starts a SSHFS server on the macOS host, and then
mounts it via SSHFS (FUSE) inside the Linux VM. That's fine, because
Linux have absolutely no issue with FUSE stuff.

The other way around however, we would need FUSE on the macOS side in
order to mount a SSHFS server running inside the VM. No bueno, because
we're doing all this jazz to avoid dealing with FUSE on macOS in the
first place. 😬

So if we're not gonna use FUSE, we need to fallback to another protocol
that's better supported on Mac, like WebDAV.

The best way I've found to do that is actually to use a simple, plain Go
WebDAV server such as [this one](https://taoofmac.com/space/til/2022/11/25/2200).

Just point the server to serve the decrypted mount point from earlier.

We also need to edit the Lima VM config in
`~/.lima/default/lima.yaml` to forward the port the WebDAV server is
listening on, so we can access it from the host system, such as:

```yaml
portForwards:
  - guestPort: 1234
```

Then on the macOS side we can do:


```sh
mkdir -p mountpoint
mount_webdav http://localhost:1234 mountpoint
```

Before going with the custom Go solution, I've tried
[phởdav](https://wiki.gnome.org/phodav), because unlike most WebDAV
servers, it doesn't require any kind of hairy configuration, and can be
spawned in a ad hoc way that just works. But the performance wasn't as
good as the Go version. I've also tried NFS, but that was much even
slower.

That said, don't get your hopes too high. Even with the Go version, the
performance wasn't super fast, but I believe it's mainly because of
being run over SSHFS, so your mileage may vary depending on the network
bandwidth you have with your offsite server. But as a fallback, I'll
call it good enough anyway.
