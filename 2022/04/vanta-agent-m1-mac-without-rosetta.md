# Install the Vanta agent on a M1 Mac without Rosetta (and more)
April 30, 2022

<div class="note">

**Update:** Vanta eventually released a version that's M1-native so
neither Rosetta nor the workaround below is needed anymore.

What you may still be interested with is the part where I
[observe the network logs](#spying-on-the-spyware-and-monitoring-its-network-traffic)
of the Vanta agent to see if it's doing anything fishy, as well as the
update where I tell you [what I found those logs](#analyzing-the-mitmproxy-logs).

</div>

Did you recently get asked to install the Vanta agent on your M1 Mac and
got prompted to install Rosetta for it to run?

Do you like running a Rosetta-free system?

Then this post is for you.

Also if you also don't like running (benevolent) spyware with `root`
permissions, and want to monitor what the spyware is precisely spying
about you, read on, I have a few other things for you. 😉

## The Rosetta thing

I wrote [a more generic post](repackage-macos-app-m1-support-without-rosetta.md)
about this, and I encourage you to read it if you want to learn about
all the technical details, but for the purpose of this Vanta-specific
article, I'll keep it short. The objective is to:

1. Extract the `vanta.pkg` installer to access its contents.
1. Update the `Distribution` XML file to flag ARM support (removes the
   Rosetta prompt).
1. Extract the `vanta-raw.pkg/Payload` archive and replace the x86-64
   `osqueryd` binary by the universal binary from [version 5.2.2](https://github.com/osquery/osquery/releases/tag/5.2.2)
   (or greater).
1. Repackage the whole thing.

Assuming you have `vanta.pkg` already downloaded (otherwise you can get
it from [here](https://github.com/VantaInc/vanta-agent-scripts/blob/b4e421f11d51896d274ae5782884c90f6ba5ce27/install-macos.sh#L8])),
run the following commands:

```sh
# Create a directory to extract the package into
mkdir vanta
cd vanta

# Extract the package in the current directory
xar -xf ../vanta.pkg

# Go in the subpackage
cd vanta-raw.pkg

# Create a directory to extract the payload into
mkdir PayloadOut
cd PayloadOut

# Extract the payload in the current directory
cpio -i < ../Payload

# Stream the tar archive for `osqueryd` 5.2.2 (follow redirects) and extract it to the current directory
curl --location 'https://github.com/osquery/osquery/releases/download/5.2.2/osqueryd-macos-bare-5.2.2.tar.gz' | tar xf -

# We now have a `osqueryd` binary that we can move to the right location
mv osqueryd usr/local/vanta

# Recreate the cpio archive
find . | cpio -oz --owner 0:80 > ../Payload

# Go back to the parent directory and remove our temporary `PayloadOut` directory
cd ..
rm -rf PayloadOut

# Go back to the parent directory
cd ..

# Flag ARM support in the `Distribution` file
sed -i '' 's/<allowed-os-versions>/<options hostArchitectures="arm64,x86_64" \/>\n    <allowed-os-versions>/' Distribution

# Alternative with GNU sed
# gsed -i '/<installer-gui-script/a \    <options hostArchitectures="arm64,x86_64" />' Distribution

# Repackage the main installer
xar --compression none -cf ../vanta-new.pkg .
```

This will give you a `vanta-new.pkg` installer that now has proper ARM
support and won't prompt you to install Rosetta!

Again if you want to know precisely how this works, check out my
[detailed article on the topic](repackage-macos-app-m1-support-without-rosetta.md).

But while having native M1 support is great, there's still a few things
that concern me about this program.

For example, I didn't actually run that installer on my machine because
it requires `root` permissions and I don't want to run untrusted code as
`root`. I still tested the package in a macOS VM (which is [surprisingly easy to do nowdays](macos-docker-linux-wayland.md))
to confirm that the script works end-to-end. But for a machine I care
about, how do we install and run that thing with only user privileges?

## Installing and running Vanta without `root` privilege

It's unclear what the this program does concretely, but it
[claims](https://help.vanta.com/hc/en-us/articles/360060881051-Getting-Started-with-the-Vanta-Agent)
to be read-only ("it will **not** change anything on your machine"),
despite their installer and other commands requesting `root` access
(this is fishy AF).

I don't like running as `root` anything that wasn't shipped by Apple
as part of the macOS base system, with the exception of some specific
open-source programs in very particular cases (e.g. some `nmap`
invocations and such), or programs like nginx that I trust to properly
drop privileges after starting and binding to a reserved port.

This is definitely not the case of this agent, and there's no way this
thing is going to run as `root`.

So how do we run it without giving it superuser privileges? First, we
need to dissect the package a bit and install it manually.

In the [first part](#the-rosetta-thing), we already extracted the
installer as well as the `Payload` archive, in a `PayloadOut` directory.
We'll start from there, and go in the `PayloadOut` directory to manually
install everything we need.

First we'll copy `Library/LaunchDaemons/com.vanta.metalauncher.plist`
to `~/Library/LaunchAgents/com.vanta.metalauncher.plist`. Why? Launch
daemons are systematically run as `root` while launch agents are user
services. Their format is otherwise compatible so that makes things easy
for us.

```sh
cp Library/LaunchDaemons/com.vanta.metalauncher.plist ~/Library/LaunchAgents
```

We also replace the error log path in that file to point to a location
where we actually have write permission:

```sh
sed -i '' 's,/var/log/vanta_stderr.log,/usr/local/vanta/log/vanta_stderr.log,' ~/Library/LaunchAgents/com.vanta.metalauncher.plist
```

Then we can copy `etc/vanta.conf` and `usr/local/vanta` to `/etc/` and
`/usr/local` respectively.

```sh
sudo cp etc/vanta.conf /etc
sudo cp -r usr/local/vanta /usr/local
```

<div class="note">

**Note:** OK I lied earlier, we do need `root` permission for this step.
But at no point in this section we'll run third-party code as `root`,
and that's what I intended by "without `root` privilege".

Also, keep in mind that we need to copy the `vanta` directory to
`/usr/local` because that path is actually hardcoded everywhere in the
software binaries so we can't easily run it from another location.

</div>

Vanta asserts that some binaries are owned by `root`, and refuses to run
otherwise. Once owned by `root` though, the program runs just fine
even from a user account.

```sh
sudo chown root:admin /usr/local/vanta/launcher
sudo chown root:admin /usr/local/vanta/osqueryd
```

Then, edit the `/etc/vanta.conf` file to set your agent key and email.

Finally we can start the service:

```sh
launchctl load -w ~/Library/LaunchAgents/com.vanta.metalauncher.plist
```

You can alternatively start the agent from any CLI instead of using
[launchd](https://en.wikipedia.org/wiki/Launchd):

```sh
/usr/local/vanta/metalauncher
```

<div class="note">

**Note:** the agent needs to be started using an absolute path if you
want the `vanta-cli` and the Vanta app in the tray to report that the
agent is running. If you `cd /usr/local/vanta` and run `./metalauncher`,
those other tools will think it's not running even though the agent is
actually running and reporting properly. 😅

</div>

And we're up! The logs are happily reporting that everything is running
fine, and the menu bar app (if you chose to run it) also reports that
the agent is running.

<div class="note">

**Note:** if you don't want your menu bar to be "polluted" by the Vanta
icon, I think there's a setting to hide it, or even better, just get rid
of `/usr/local/vanta/Vanta Agent.app` and you won't see it ever again!

All that app seems to be really doing is `ps aux | grep /usr/local/vanta/metalauncher`
to check that the agent is running, so you can easily do that yourself
if you want.

</div>

> But Val, how do you know that the agent is working properly after you
> installed it in such an esoteric way?

Well, thanks to [the VM](macos-docker-linux-wayland.md) I mentioned
earlier, I could test that the network traffic of the agent installed
with the original x86-64 package is identical to that of my method
without `root`. 😁

> But Val, how do you see the network traffic of the app? It's all HTTPS
> and stuff.

Well...

## Spying on the spyware and monitoring its network traffic

This agent is essentially a spyware that employees willingly install on
their work computer (or employers secretly install in some less ethical
cases) to spy on them with good intentions.

I'm more comfortable being spied on when I know precisely what is
captured and what is not. A salesperson can always say "don't worry, we
respect your privacy", but I tend to trust HTTPS traffic logs better. 😏

### Ways to sniff packets

There's a multitude of ways to sniff network traffic from an app. If all
you care about is transport layer data (e.g. raw TCP or UDP traffic),
you can easily monitor it with tools like [`tcpdump(8)`](https://linux.die.net/man/8/tcpdump)
or Wireshark. But for encrypted HTTPS traffic, that won't cut it (and
that's the whole point of HTTPS).

When you have some control over the application you want to monitor, or
if it natively supports running through a proxy, a logging HTTPS proxy
like [mitmproxy](https://mitmproxy.org/) is really useful. Some software
support communicating over a proxy through the pretty common
`http_proxy` and `https_proxy` environment variables. Others support
configuring a proxy via configuration files, UI, or command line
arguments. If this is your case, you're in luck, and you can use those
means to make that program run its HTTPS traffic through mitmproxy!

Otherwise, you need to dig deeper and tools like
[`tsocks(1)`](https://linux.die.net/man/8/tsocks),
[ProxyChains](https://github.com/haad/proxychains),
[ProxyChains-NG](https://github.com/rofl0r/proxychains-ng) and
[graftcp](https://github.com/hmgle/graftcp) (my personal favorite),
can really help. I wrote a [dedicated article on the matter](graftcp-inspect-https-traffic-proxy.md)
if you're interested!

### The `--proxy_hostname` argument

In our case, it turns out that Vanta uses the open-source
[osquery](https://github.com/osquery/osquery) program, which allows
defining a custom proxy (see `--proxy_hostname` on [this page](https://osquery.readthedocs.io/en/stable/deployment/remote/))!

So all we need to do is add our own `--proxy_hostname` to the `osqueryd`
arguments. While we don't control the invocation of `osqueryd` (it's in
the Vanta launcher binary), we can easily achieve this by wrapping the
`osqueryd` binary with a shell script:

```sh
mv osqueryd osqueryd-orig

cat << EOF > osqueryd
#!/bin/sh -e

exec /usr/local/vanta/osqueryd-orig --proxy_hostname=localhost:1337 "$@"
EOF

chmod +x osqueryd
```

With that shell script, we invoke the original `osqueryd` binary,
passing our custom `--proxy_hostname` option (here with a proxy running
on port 1337), and otherwise forwarding all other arguments.

### What about certificates?

In order to intercept HTTPS traffic, mitmproxy uses its own certificate,
that you can find in `~/.mitmproxy/mitmproxy-ca-cert.pem`. You can add
it to your system's trusted certificates list, and as long as the
software you're monitoring uses the system CA certificates list, you
should be good!

However Vanta pins their own certificate chain (using the
`--tls_server_certs` option), ignoring the certificates trusted at the
OS level.

The good news is that this pinned certificate is stored in
`/usr/local/vanta/cert.pem`, and we can just replace it with the
mitmproxy certificate!

```sh
sudo cat ~/.mitmproxy/mitmproxy-ca-cert.pem > /usr/local/vanta/cert.pem
```

After that, and restarting the service, we should be able to monitor the
traffic:

```sh
launchctl unload ~/Library/LaunchAgents/com.vanta.metalauncher.plist
launchctl load ~/Library/LaunchAgents/com.vanta.metalauncher.plist
```

### Dump with mitmdump

mitmproxy is great to interactively monitor the intercepted traffic, but
you don't want to be watching that all the time. Instead, mitmdump can
be used to log the captured traffic to a file. Then you can parse that
file and query it the way you like.

```sh
mitmdump -w +/path/to/dump/file --listen-host 127.0.0.1 --listen-port 1337
```

Here, `-w` specifies the file we want to log to, and it's prefixed by
`+` because we want to append to it instead of truncating it. The other
arguments are self-explanatory.

To start it as a launch agent the same way we start the Vanta agent, we
can add the following to `~/Library/LaunchAgents/mitmdump.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>KeepAlive</key>
  <true/>
  <key>Label</key>
  <string>mitmdump</string>
  <key>ProgramArguments</key>
  <array>
    <string>/path/to/mitmdump</string>
    <string>-w</string>
    <string>+/path/to/dump/file</string>
    <string>--listen-host</string>
    <string>127.0.0.1</string>
    <string>--listen-port</string>
    <string>1337</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
```

And enable it with:

```sh
launchctl load -w ~/Library/LaunchAgents/mitmdump.plist
```

## Check that it all worked

Finally, you can confirm that the agent is registered properly after all
those tweaks by checking the following link:

```
https://app.vanta.com/agent/info?uuid=YOUR-HARDWARE-UUID
```

Where `YOUR-HARDWARE-UUID` is your hardware UUID as it can be found in
the Apple menu, in **About This Mac > System Report > Hardware UUID**.

## Analyzing the mitmproxy logs

After monitoring the mitmproxy logs of the Vanta agent over a few
months, I didn't find anything suspicious.

At least for my employer's configuration (SOC 2 type 1 compliance), they
only check the OS version, whether or not the disk is encrypted,
whether or not my account has a password, and if there's an autolocking
mechanism after a precise period of inactivity.

It also reports the version of each browser extensions and installed
apps, the list of users in the system, as well as the public SSH keys
allowed to access my user account.

Periodically, it updates a list of known malware paths and fingerprints,
in order to check that those are not found on the system.

Finally there's a mechanism that allows the server it's registered with
to send "custom queries" but it was not used during the period I
monitored it. If it was to be used it, their API doesn't seem to allow
running arbitrary shell commands, rather it could run read-only
"queries" as exposed by the [osquery](https://github.com/osquery/osquery)
SQL-like interface which is something to keep in mind.

Based on those observations, I saw no problem (for my own standards)
running the agent on a work computer solely dedicated to the company
that requires running the agent.

## Conclusion

As an abundance of caution, I wouldn't run the Vanta agent on a computer
that I also use as a personal machine, nor on a computer that I use to
work with other clients.

Therefore, **I require each of my clients who need the Vanta agent to provide me
with a dedicated work machine**. Luckily it's only 2 of them for now. 😆

Anyway, I don't think it would be easy to make 2 independent
registrations of the Vanta agent cohabitate on the same computer, let
alone the fact that doing so would more likely be considered as a SOC 2
violation.

That's all for today! I hope you found on this page what is it you were
looking for, and that you learnt a thing or two along the way! Or at
least that you enjoyed reading through my adventures messing around
with this program. 😂
