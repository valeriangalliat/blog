# How can rsync work on a host without shell access? 🤔
And SFTP, SCP, BorgBackup...  
April 9, 2022

## TLDR

It does not. But sometimes, hosting providers use a trick so that you
don't have shell access but rsync thinks it does...

## The case of a file hosting provider

I use a [Hetzner storage box](https://www.hetzner.com/storage/storage-box?country=us)
for my backups. They have a super competitive offer that can get you 1
TB of storage for €2.90 per month, or 5 TB for €9.90!

On their [features page](https://www.hetzner.com/storage/storage-box?country=us)
they list they support a number of protocols, including **SFTP, SCP,
BorgBackup, and rsync over SSH**.

All of those protocols happen over a SSH connection, yet Hetzner doesn't
give us SSH access to the box:

```
$ ssh u123456@u123456.your-storagebox.de
PTY allocation request failed on channel 0

+-------------------------------------------------------------------------------+
| Your authentication works but we do not support interactive logins.           |
| For more information on how to access your Storage Box please check our Docs: |
| https://docs.hetzner.com/robot/storage-box/access/access-ssh-rsync-borg       |
+-------------------------------------------------------------------------------+

Connection to u123456.your-storagebox.de closed.
```

Let's assume the following `~/.ssh/config` for further commands for
simplicity, so that we can just `ssh hetzner`:

```
Host hetzner
    HostName u123456.your-storagebox.de
    User u123456
```

While interactive SSH is not allowed, we can try running a command
directly:

```
$ ssh hetzner ls
file1
file2
file3
```

Interesting. What other commands do they allow?

```
$ ssh hetzner cp file3 file4
Command not found

$ ssh hetzner cat file1
Command not found

$ ssh hetzner du -sh .
Command not found

$ ssh hetzner pwd
Command not found

$ ssh hetzner whoami
Command not found

$ ssh hetzner rm file3
Command not found
```

Well, not much. So by what sorcery are SFTP, SCP, BorgBackup and rsync
able to work over this connection?

```
$ sftp hetzner
Connected to hetzner.
sftp>

$ scp file4 hetzner:
file4

$ rsync -v file5 hetnzer:
file5

$ ssh hetzner ls file4 file5
file4
file5
```

To understand, let's dig in the internals of SFTP, SCP, BorgBackup and
rsync.

## SFTP

SFTP is actually the odd one in the room. But we'll start with it
nevertheless.

Using `-v` to enable debug output gives one interesting line near the
end of the log:

```
$ sftp -v hetzner
...
debug1: Sending subsystem: sftp
...
```

It looks like we're dealing with something called SSH subsystems. A good
way to find more about them is to search
[how to enable SFTP but disallow SSH](https://serverfault.com/questions/354615/allow-sftp-but-disallow-ssh).

Here, we meet our SSH server subsystem again, which is typically
configured on the server as:

```conf
Subsystem sftp internal-sftp
```

From the [`ssh(1)`](https://linux.die.net/man/1/ssh) man page, we can
see that `ssh -s` allows to pass a subsystem where we would normally
pass a command, e.g:

```
$ ssh hetzner -s sftp
```

This command hangs, meanings the remote server is waiting for SFTP
commands. Since it's a binary protocol, we won't be able to play with it
directly, but this is the connection over which a normal SFTP client
would be able to do its magic. Sweet!

## SCP

Let's use the verbose/debug mode trick like we did previously with SFTP:

```
$ scp -v file4 hetzner:
...
debug1: Sending command: scp -v -t .
...
```

Here, the relevant part of the debug output is where `scp` sends the
remote command `scp -v -t .`.

`-v` is for the verbose mode we specified, but if we look at the
[`scp(1)`](https://linux.die.net/man/1/scp) man page, there's nothing
for `-t`.

We can look at
[the source code](https://github.com/openssh/openssh-portable/blob/90452c8b69d065b7c7c285ff78b81418a75bcd76/scp.c#L575)
where they parse the command line arguments:

```c
case 'f':    /* "from" */
    iamremote = 1;
    fflag = 1;
    break;
case 't':    /* "to" */
    iamremote = 1;
    tflag = 1;
```

So we learn that `-f` or `-t` are used internally to trigger the remote
mode. Because in our case we were sending a file to the remote host, we
entered `-t` mode, but if we were downloading a file form the host, we
would likely see `-f`. Let's try:

```
$ scp -v hetzner:file4 .
...
debug1: Sending command: scp -v -f file4
...
```

So it's through invoking `scp` on the remote host over SSH that our
local `scp` is able to transfer files. But how is that possible? We saw
earlier that basically every command but `ls` was returning "command not
found"! And we can confirm `scp` is not present on the remote host:

```
$ ssh hetzner scp
Command not found
```

Or is it? Let's try the full command that `scp` would normally run on
the remote host...

```
$ ssh hetzner scp -t .
$ ssh hetzner scp -f file4
```

Both those commands hang, meaning that Hetzner actually ran them, and we
now have a communication channel with the remote `scp` process!

So Hetzner disallowed us to run `scp` directly on the remote host, but
they whitelisted the specific arguments that `scp` would internally pass
to start the remote process. Smart.

## BorgBackup

Now we know the pattern, it's easy to confirm that they do the same
whitelisting for BorgBackup. We can see that [`borg serve`](https://borgbackup.readthedocs.io/en/stable/usage/serve.html)
is used to start the remote process.

```
$ ssh hetzner borg
Command not found

$ ssh hetzner borg --help
Command not found

$ ssh hetzner borg serve
```

The last command hangs, and again we exposed the way Borg internally
opens a communication channel with a Borg implementation on the remote
server!

## rsync

One more time, we leverage the verbose mode, this time with `-vv` to get
extra debug output, to see what rsync does internally:

```
$ rsync -vv file5 hetzner:
opening connection using: ssh hetzner rsync --server -vve.LsfxCIvu . .  (7 args)
delta-transmission enabled
file5
...
```

Sweet. Let's try to run this manually:

```
$ ssh hetzner rsync
Command not found

$ ssh hetzner rsync --help
Command not found

$ ssh hetzner rsync --server -vve.LsfxCIvu . .
```

And again, Hetzner allowed the last command and we have an open
communication channel with the remote rsync process!

### Digging deeper just for fun

If you're curious, there's [a Server Fault question](https://serverfault.com/questions/793669/what-is-the-rsync-option-logdtprze-ilsf-for/1096808)
about the meaning of the `-vve.LsfxCIvu` part.

The answers there were a pretty good start, but there was something
fishy and unexplained about the `.` in the middle, and I wasn't quite
satisfied. So [I dug I bit more](https://serverfault.com/a/1096808).

In the case of `-vve.LsfxCIvu`, it's actually equivalent to `-v -v -e '.LsfxCIvu'`,
because of the way `popt(3)`'s `POPT_ARG_STRING` parses command line
options (the library used by rsync to parse options), which is quite a
common behavior for Unix commands short options.

The trick is that `-e` is interpreted differently when we're in
`--server` mode, in a way that's not related to the `-e` client option
from the man page, that is normally the short version of `--rsh`,
allowing to specify the remote shell to use.

Setting `-e` or `--rsh` will have the options parser populate the
`shell_cmd` variable, but [they hijack it in server mode](https://github.com/WayneD/rsync/blob/13c4019e94015b234697c75d9d3624862e962d3c/compat.c#L160)
to populate a `client_info` variable instead, which is used
[differently](https://github.com/WayneD/rsync/blob/13c4019e94015b234697c75d9d3624862e962d3c/compat.c#L134),
to define a number of internal protocol compatibility options.

We can look at [the code that creates the value for the `-e` option](https://github.com/WayneD/rsync/blob/f44e76b65c5819edb1a5b2fbbe732d5d214b35de/options.c#L2951)
to get an idea of what those options do. In my case:

* `L`: symlink time-setting support
* `s`: symlink iconv translation support
* `f`: `flist` I/O-error safety support
* `x`: `xattr` hardlink optimization not desired
* `C`: support checksum seed order fix
* `I`: support `inplace_partial` behavior
* `v`: use `varint` for `flist` & compat flags; negotiate checksum
* `u`: include name of `uid 0` & `gid 0` in the `id` map

I didn't really need to know that `-vve.LsfxCIvu` means
`-v -v -e '.LsfxCIvu'` and not `-v -v -e . -L -s -f -x -C -I -v -u`? No.
Does this makes my life any better? Not really. But there's an invisible
force that pushes me to spend ridiculous amounts of time to make sense
of this kind of things.

## Conclusion

SFTP, SCP, BorgBackup and rsync all work on a client/server model, where
the command is run both on the client *and* the server, and communicate
together over SSH. It means that the command needs to be installed on
the remote server as well, and allowed to be run over SSH.

rsync and BorgBackup can achieve great performance to synchronize files
on a storage server like Hetzner, because despite not having shell
access on that server, the specific commands used by those tools to
start a remote process are whitelisted.

For other tools like [restic](https://restic.net/), because Hetzner
doesn't support their custom server protocol, they are constrained to
use the more generic (and limited) commands of SFTP, which doesn't allow
optimal performance.

So if you were wondering how all those tools can run code on your
storage box despite you being denied shell access, now you know!
