---
tweet: https://x.com/valeriangalliat/status/1520528360182620160
---

# graftcp: inspect any program's HTTPS traffic through a proxy!
April 30, 2022

Recently, I [needed to sniff an app's HTTPS traffic](vanta-agent-m1-mac-without-rosetta.html#spying-on-the-spyware-and-monitoring-its-network-traffic).

While sniffing plaintext HTTP traffic is easy, by targeting the
transport layer with tools like [`tcpdump(8)`](https://linux.die.net/man/8/tcpdump)
or Wireshark, *HTTPS is another beast*.

Because of the TLS encryption, all we see at the transport layer is a
bunch of unusable encrypted data (and that's the whole point of HTTPS).
So we need to resort to solutions at a higher layer in the stack.

My go-to for this kind of task is [mitmproxy](https://mitmproxy.org/),
an interactive HTTPS proxy, as well as its headless counterpart
*mitmdump*.

But those are only half of the solution. A proxy server is useless until
we route HTTPS traffic *through it*. And depending on the context, this
task can go from pretty trivial to quite tricky.

## Common ways to configure a proxy

There's 3 main ways that you can use to configure a proxy:

1. the OS level,
1. the application level,
1. the environment level.

I already [gave an introduction to mitmproxy](../../2021/07/intercept-macos-app-traffic-mitmproxy.md)
last year on the blog, in which I explored [the OS level](../../2021/07/intercept-macos-app-traffic-mitmproxy.md#first-try-macos-network-proxy-settings)
and [the app level](../../2021/07/intercept-macos-app-traffic-mitmproxy.md#second-try-spotify-supports-app-level-proxy-settings),
but I'll give a quick refresher here.

### The OS level

Your OS usually lets you configure a proxy in the networking settings.
For example on macOS it's in the advanced network preferences, and on
Android it's in the advanced Wi-Fi settings.

It's a good way to globally configure a proxy, but there's no guarantee
that apps are going to respect it. Typically, the default browser that
ships with the OS (e.g. Safari) will use it, and some third-party
browsers might too, but in general most other apps just ignore it. Not
so good.

### The application level

While most apps don't respect OS-level proxy configuration, some can
provide you with a way to configure a proxy at their own level.

Typically this will be Firefox's connection settings, with its very own
proxy configuration, Spotify's advanced settings that [let you configure a proxy](../../2021/07/intercept-macos-app-traffic-mitmproxy.md#second-try-spotify-supports-app-level-proxy-settings),
or more recently I've explored [the `--proxy_hostname` argument](vanta-agent-m1-mac-without-rosetta.md#the-proxy-hostname-argument)
to the `osqueryd` program.

But it's up to the app's developers to decide if they want or not to let
you configure a proxy, and how rigorously they use it... (they might use
the proxy for some requests but not all of them).

### The environment level

Finally, there are two pretty commonly used environment variables
(although I believe not standard per se) to configure a proxy:
`http_proxy` and `https_proxy`. They respectively configure a proxy to
route HTTP and HTTPS traffic through.

For example the Python language [supports those](https://github.com/python/cpython/blob/a03a09e068435f47d02649dda93988dc44ffaaf1/Lib/urllib/request.py#L2507)
in its native `urllib` package, and while Node.js [doesn't](https://github.com/nodejs/node/issues/8381),
the popular [axios](https://github.com/axios/axios) library
[also supports them](https://github.com/axios/axios/blob/bc733fec78326609e751187c9d453cee9bf1993a/lib/adapters/http.js#L186)
out of the box.

So basically, it might or might not work depending on the implementation
of the software that you're using, but it's definitely worth trying!

## When nothing works: the hacker way

So far all we've done is configuring a proxy in interfaces that
explicitly allow us to set a proxy. But sometimes this is just not
enough. That's when we resort to ways to configure a proxy in places
that don't explicitly let us do so. 😏

There's two ways to do this. The most common one is to leverage
`LD_PRELOAD` with dynamically linked binaries to override symbols in a
library. This is the approach that [`tsocks(1)`](https://linux.die.net/man/8/tsocks),
[ProxyChains](https://github.com/haad/proxychains) and [ProxyChains-NG](https://github.com/rofl0r/proxychains-ng)
use, hijacking the [`connect(2)`](https://linux.die.net/man/2/connect)
[libc](https://en.wikipedia.org/wiki/C_standard_library) function to
route requests through the proxy of your choice.

This is a great method when using programs that are dynamically linked
against libc, but it will fail for statically liked programs, as well as
programs that don't use libc (Go programs for example).

This is where [graftcp](https://github.com/hmgle/graftcp) shines.
Instead of hooking at the libc level, it leverages
[`ptrace(2)`](https://linux.die.net/man/2/ptrace) to modify the
[`connect(3)`](https://linux.die.net/man/3/connect) syscall arguments!
Essentially, it's acting at a lower level and that's how it's able to
proxy against statically liked programs that don't use libc. Their
detailed [how does it work](https://github.com/hmgle/graftcp#principles)
explanation is really worth a read.

### Installation

```sh
git clone https://github.com/hmgle/graftcp.git
cd graftcp
make
```

### Usage

From there, you can use `local/graftcp-local` to start the graftcp
server, and configure it to use your proxy (for example mitmproxy
starts a HTTP proxy on port 8080 by default). Because graftcp also
defaults to a SOCKS5 proxy on `localhost:1080`, we need to force it to
use the HTTP proxy we configured by using `--select_proxy_mode
only_http_proxy`:

```sh
local/graftcp-local --http_proxy localhost:8080 --select_proxy_mode only_http_proxy
```

We can do the same thing by "emptying" the preconfigured SOCKS5 proxy:

```sh
local/graftcp-local --http_proxy localhost:8080 --socks5 ''
```

Or we can instead run mitmproxy as a SOCKS5 proxy, here on port 1080
(the default for graftcp):

```sh
mitmproxy --mode socks5 -p 1080
```

Then we can run `local/graftcp-local` without arguments and it'll just
work.

Either way, once the proxy and `local/graftcp-local` program is started,
we can prefix any command with `./graftcp` to force it to run its
network calls through the proxy!

```sh
./graftcp curl https://www.codejam.info/
```

### Dealing with certificates

However, this should complain that the SSL certificate from mitmproxy is
untrusted. We can make it go through by appending `-k` (`--insecure`) to
the `curl` command:

```sh
./graftcp curl https://www.codejam.info/ --insecure
```

A better solution though would be to add the mitmproxy CA certificate
found in `~/.mitmproxy/mitmproxy-ca-cert.pem` to the system trusted
certificates. This will vary depending on your OS and distribution, but
in my case that would be done with:

```sh
sudo trust anchor ~/.mitmproxy/mitmproxy-ca-cert.pem
```

Then the `curl` command should work without `--insecure`!

### Short version

Finally, if you don't want to bother running `local/graftcp-local` and
`./graftcp` separately, you can instead use `local/mgraftcp`. If you
still use the SOCKS5 proxy on port 1080:

```sh
local/mgraftcp curl https://www.codejam.info/
```

Or with a HTTP proxy on port 8080:

```sh
local/mgraftcp --http_proxy localhost:8080 --select_proxy_mode only_http_proxy curl https://www.codejam.info/
```

This is useful if you only want to use graftcp for a single command, or
don't mind configure the proxy settings every single time. Otherwise the
graftcp server method with `local/graftcp-local` works better as you
only have to configure your proxy once and any call to `./graftcp` will
use it!

## Conclusion

graftcp is a really powerful tool that allows you to redirect HTTPS
traffic through a proxy of your choice, even in situations where this
wouldn't be allowed or planned for.

Because I love inspecting programs' network traffic to know how they
work, and it's not always easy to get access to their requests logs,
graftcp is now a go-to of mine for this kind of task, as it's proven to
work flawlessly and very reliably, even with statically linked binaries
and programs that don't link against libc like it's the case with Go!

I hope you learnt something with this post, and I wish you a happy
network sniffing. 🤘
