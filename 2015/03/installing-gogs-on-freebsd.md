Installing Gogs on FreeBSD
==========================
March 7, 2015

[Gogs] is a self-hosted Git service, not unlike GitHub, but lightweight
and open source. Here's a small tutorial to install it in its own jail
on a FreeBSD host.

[Gogs]: http://gogs.io/

Preparation
-----------

First, create the jail, start it, and open a shell into it. You can
skip this step if you don't want to install it into a jail. Assuming
you use [ezjail]:

```sh
ezjail-admin create gogs $ip
ezjail-admin start gogs
ezjail-admin console gogs
```

Where `$ip` is the jail IP address.

[ezjail]: http://erdgeist.org/arts/software/ezjail/

Then install the required packages:

```sh
pkg install go git gcc
```

Add the `git` user and open a shell with it:

```sh
pw useradd git -m
su - git
```

And setup the Go environment (locally and permanently):

```sh
GOPATH=$HOME/go; export GOPATH
echo 'GOPATH=$HOME/go; export GOPATH' >> ~/.profile
```

Installation
------------

We can now install Gogs using the Go package manager:

```sh
CC=gcc48 go get -u --tags sqlite github.com/gogits/gogs
```

`CC=gcc48` is required to force the build tool to use GCC instead of
Clang (default on FreeBSD) for the compilation, because it appears some
sources fail to be compiled with Clang.

The `-u` flag tells the Go package manager to use the network to fetch
the package and its dependencies.

Here, I choose to use Gogs with SQLite backend, by using `--tags
sqlite`.

I made a symlink to the Gogs directory so I can easily access it:

```sh
ln -s go/src/github.com/gogits/gogs gogs
```

Then build Gogs itself (the previous command only fetched it):

```sh
cd gogs
CC=gcc48 go build --tags sqlite
```

Configuration
-------------

The default configuration can be extended by creating
`custom/conf/app.ini`.

```sh
mkdir -p custom/conf
vim custom/conf/app.ini
```

We need to at least configure the database, and since we're on FreeBSD
and Bash is not installed by default, we must also tell Gogs to use `sh`
instead (needed for Git hooks), see `SCRIPT_TYPE` option. Here's my
whole configuration:

```ini
RUN_USER = git
RUN_MODE = prod

[database]
DB_TYPE = sqlite3
PATH = data/gogs.db

[repository]
ROOT = /home/git/gogs-repositories
SCRIPT_TYPE = sh

[server]
DOMAIN = git.codejam.info
ROOT_URL = https://git.codejam.info/
HTTP_PORT = 3000
DISABLE_SSH = true
LANDING_PAGE = explore

[session]
PROVIDER = file

[log]
MODE = file

[security]
INSTALL_LOCK = true
SECRET_KEY = ThisIsNotMySecretKey

[service]
DISABLE_REGISTRATION = true
```

See the [other configuration options] and tweak to your tastes!

[other configuration options]: http://gogs.io/docs/advanced/configuration_cheat_sheet.html

Execution
---------

Run the server with:

```sh
./gogs web
```

Ideally you'll write an init script for this, but I'm lazy and I just
put it in a `@reboot` entry in the crontab:

```sh
PATH=/bin:/usr/bin:/usr/local/bin
@reboot cd ~/gogs && ./gogs web > logs/main.log
```

Updating
--------

To update Gogs to the latest version, basically replay the installation
process:

```sh
CC=gcc48 go get -u --tags sqlite github.com/gogits/gogs
cd ~/gogs
CC=gcc48 go build --tags sqlite
```
