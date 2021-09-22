# How I set up a minimalist Debian host with nginx and Let's Encrypt
September 22, 2021

It's something I've had to do more than once this year so I think it's
about time to write a blog post.

<div class="note">

**Note:** in this post (including the title), I use "Let's Encrypt"
because it's the term most people know and will look up, but what I mean
is technically the <abbr title="Automatic certificate management environment">ACME</abbr>
protocol with any compatible certificate authority.

[Let's Encrypt](https://letsencrypt.org/) is one of those certificate
authorities, but I personally use [ZeroSSL](https://zerossl.com/) which
is another ACME-compatible authority to provide free certificates.

</div>

## Why do I spawn Debian VMs?

Let's start with the why I'm doing that. See, Google Cloud has
[a cool thing](https://cloud.google.com/free/docs/gcp-free-tier/#compute)
where they allow you to run a `e2-micro` instance for free per billing
account, with up to 30 GB of storage, and as long as you pay for egress
(outgoing) traffic.

This is one of the cheapest ways that I know of to host a proof of
concept, <abbr title="Minimum viable product">MVP</abbr> or a very small
or lightweight project like this blog.

Google Cloud defaults their VM image to latest stable Debian, which I
find to be a good base for a server when you don't want to spend a lot
of time setting things up and don't want to think too much about it.

## Why do I install nginx and Let's Encrypt?

Most of the time I spawn such a VM, it's to run some kind of web
service over HTTPS. nginx is my favorite web server, and ACME is my
favorite way to manage TLS certificates (see note above about my usage
of the term "Let's Encrypt").

## What about infrastructure as code?

I won't go into this topic in this blog post because there's a fuckton
of ways you could want to code your infrastructure and provision your
servers depending on your needs.

This is out of scope for this article, but feel free to adapt it to
whatever tools you use! Personally, my favorite provisioning tool is
`/bin/sh` and this post is a breakdown of my script with detailed
explanations about everything it's doing.

Now the context is set, let's get into how I set up everything in a
minimalistic way (I like to keep things simple).

## Preventing the bloat on Debian

First things first, I start every of my Debian installations by adding
this `apt.conf` I shared on this blog over 7 years ago, to [keep Debian clean and minimal](../../2014/09/keeping-debian-clean-and-minimal.html).

The gist of it is that by default Debian packages can come with
"recommended packages" and "suggested packages", and APT automatically
installs the recommended ones by default.

<div class="note">

**Note:** APT also used to install the suggested packages by default,
which is how we ended up with `imagemagick` on the system after
installing `nmap` like mentioned in the article above.

It looks like I wasn't the only one to be bugged by this and this
behavior is no longer the default.

</div>

I like to explicitly install every package that's not a hard dependency,
so I use the following config to make sure nothing extra is installed by
default.

```sh
cat << EOF > /etc/apt/apt.conf
APT::Install-Recommends false;
APT::Install-Suggests false;
APT::AutoRemove::RecommendsImportant false;
APT::AutoRemove::SuggestsImportant false;
EOF
```

It also configures APT to consider previously installed recommendations
and suggestions unimportant, meaning that they'll be wiped in the next
`apt autoremove`. This won't do anything on most fresh installations,
but if installing this configuration in an existing system, you might
want to double-check that list before removing the packages marked as
"no longer necessary".

After that, APT will only install what's strictly required by default,
and on top of the "suggested packages" list, it'll also display a
"recommended packages" informational list, instead of automatically
installing them. Neat.

Also note that `apt autoremove`, like `apt remove`, will keep the
configuration files of the removed packages on the system, and there's
no equivalent of `apt purge` like `apt autopurge`.

<div class="note">

**Note:** I just tried out of curiosity and even though undocumented, it
looks like [`apt autopurge` exists](https://github.com/Debian/apt/blob/766b24b7f7484751950c76bc66d3d6cdeaf949a5/apt-private/private-install.cc#L608)
and does exactly what you would expect!

So I would recommend running `apt autopurge` instead of `apt autoremove`
so that it also removes the configuration files of the packages it
removes.

</div>

Finally, if you used `apt remove` or `apt autoremove`, you can still
purge the dangling configuration files with the [following command](https://askubuntu.com/a/279432):

```sh
apt purge $(dpkg --get-selections | grep deinstall | cut -f1)
```

This will purge the configuration files of all packages that were ever
deinstalled and left with existing configuration files in place.

## Installing the essentials

In most Unix systems that I use, I'll install the following packages:

```sh
apt install tmux vim git htop ca-certificates
```

On top of that, on Debian I like to add the `build-essential` package if
I need to compile anything, as it depends on the most common tools that
are necessary to build software from source.

## My minimalist nginx configuration

Let's start with installing nginx.

```sh
apt install nginx
```

This will put the default Debian nginx configuration in `/etc/nginx`.

The default configuration is too much for me. I like to write my nginx
configuration from scratch. The only file I want to keep is the
[default `mime.types` file](https://github.com/nginx/nginx/blob/master/conf/mime.types).

```sh
cd /etc
mkdir nginx2
cp nginx/mime.types nginx2
rm -rf nginx
mv nginx2 nginx
```

This wipes all the default nginx configuration and only keeps the
`mime.types` file which I'll include in my custom configuration.

### Trimmed-down Debian configuration

Speaking about my custom configuration, here's the base. Everything
there is the parts of the default `nginx.conf` on Debian that I kept.
I'll post my custom additions after.

```nginx
#
# /etc/nginx/nginx.conf
#
# Based on a simplified Debian default.
#

user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    # server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
}
```

### Val's essential tweaks

From there, I tweak a few things.

```diff
     tcp_nodelay on;
     keepalive_timeout 65;
     types_hash_max_size 2048;
-    # server_tokens off;
+    server_tokens off;

     include /etc/nginx/mime.types;
     default_type application/octet-stream;

-    access_log /var/log/nginx/access.log;
+    access_log off;
     error_log /var/log/nginx/error.log;

     gzip on;
+    gzip_vary on;
+
+    # Custom list based on Debian's `/etc/nginx/mime.types`.
+    gzip_types text/html text/css text/xml application/javascript application/atom+xml application/rss+xml text/plain application/json image/svg+xml;
+
+    charset utf-8;
 }
```

* I turn `server_tokens` off to remove the `Server` HTTP response header.
* I turn off the default access log because I like to specify it per
  virtual host and I don't care about requests that didn't hit a virtual
  host.
* I enable `gzip_vary` to have the `Vary: Accept-Encoding` header in the
  responses. This is especially important when used with a caching
  server in front, because it instructs it to not mix responses with
  different `Accept-Encoding` together, preventing for example to serve
  a gzip response to a client that can only handle plain text.
* I configure more `gzip_types` than the default of just `text/html`, so
  that we automatically compress most web resources. Feel free to add
  more that makes sense to you here.
* I set `charset` to `utf-8` so that `charset=utf-8` is added to the
  `Content-Type` response header, e.g. `Content-Type: text/html; charset=utf-8`.

But we're still missing a very important part. The TLS configuration!

### TLS settings

I use [Mozilla's SSL configuration generator](https://ssl-config.mozilla.org/)
for that, with the intermediate setting, which gives me the following
(comments removed):

```nginx
ssl_certificate /path/to/signed_cert_plus_intermediates;
ssl_certificate_key /path/to/private_key;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;
ssl_dhparam /path/to/dhparam;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
add_header Strict-Transport-Security "max-age=63072000" always;
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;
```

I like to include it in the `http` block, after the `default_type`
directive.

But we don't yet have the certificates and key files that we reference
there. We still need to generate them with Let's Encrypt. We'll do that
a bit later, but until then, we need to comment those parts otherwise
the nginx config won't validate and nginx won't be able to start (or
reload).

```diff
-ssl_certificate /path/to/signed_cert_plus_intermediates;
-ssl_certificate_key /path/to/private_key;
+# ssl_certificate /path/to/signed_cert_plus_intermediates;
+# ssl_certificate_key /path/to/private_key;
 ssl_session_timeout 1d;
 ssl_session_cache shared:MozSSL:10m;
 ssl_session_tickets off;
-ssl_dhparam /path/to/dhparam;
+# ssl_dhparam /path/to/dhparam;
 ssl_protocols TLSv1.2 TLSv1.3;
 ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
 ssl_prefer_server_ciphers off;
 add_header Strict-Transport-Security "max-age=63072000" always;
 ssl_stapling on;
 ssl_stapling_verify on;
-ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;
+# ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;
```

### Default server with HTTPS and `www` redirect

I like <code><strong>http://</strong>www.codejam.info/</code> to redirect to
<code><strong>https://</strong>www.codejam.info/</code>, and also
`https://codejam.info/` to redirect to <code>https://<strong>www.</strong>codejam.info/</code>.
As a bonus, I like when <code><strong>http://</strong>codejam.info/</code>
redirects to <code><strong>https://www.</strong>codejam.info/</code> in
a single step. 😏

We'll also take this as an opportunity to configure the Let's Encrypt
webroot challenge path, so that our ACME client can automatically
generate and renew certificates.

<div class="note">

**Note:** it appears that the most common way people run ACME clients is
by letting it automatically modify their web server configuration file
to handle the ACME challenge endpoint `/.well-known/acme-challenge`
during the issuing or renewal.

Alternatively, the "webroot" method lets you configure the
`/.well-known/acme-challenge` path yourself on your web server to serve
an existing directory on the system. The ACME client will then just put
files in that directory to have them served by your web server, without
altering its configuration. This is a much simpler and more reliable
solution.

While common ACME clients like [Certbot](https://certbot.eff.org/) and
[acme.sh](https://github.com/acmesh-official/acme.sh) can handle a
variety of web server configurations, I hate the idea of a tool
modifying my `nginx.conf` which is why I use the webroot mode instead.

</div>

The following `server` blocks will do all of that. They live inside the
main `http` block which I won't include again here.

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    location / {
        return 404;
    }
}

server {
    listen 80;
    listen [::]:80;

    server_name www.codejam.info;

    location / {
        return 301 https://$host$request_uri;
    }

    location /.well-known/acme-challenge {
        root /var/www/challenges;
    }
}

server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name codejam.info;

    location / {
        return 301 https://www.$host$request_uri;
    }

    location /.well-known/acme-challenge {
        root /var/www/challenges;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name www.codejam.info;

    access_log /var/log/nginx/www.codejam.info.access.log;
    error_log /var/log/nginx/www.codejam.info.error.log;

    root /var/www/www.codejam.info;
    index index.html;

    location /.well-known/acme-challenge {
        root /var/www/challenges;
    }
}
```

The first block with `default_server` makes sure that nginx returns a
404 for every requests it sees for a domain that it doesn't know about.

The rest should be self-explanatory.

### Enabling, starting or reloading nginx

First, let's test the configuration:

```sh
nginx -t
```

If successful, we can enable the nginx service if it's not already:

```sh
systemctl enable nginx
```

Then start it:

```sh
systemctl start nginx
```

Or reload its configuration if it was already running

```sh
systemctl reload nginx
```

While in this state we don't have proper TLS certificates to handle
HTTPS yet, we have everything we need to automatically generate and
renew TLS certificates with the ACME protocol.

## Managing TLS certificates with acme.sh

<abbr title="Automatic certificate management environment">ACME</abbr>
is the protocol behind Let's Encrypt. [acme.sh](https://github.com/acmesh-official/acme.sh)
is an ACME client written in pure Unix shell. It's simple and
lightweight, unlike [Certbot](https://certbot.eff.org/), which is the
client that Let's Encrypt recommends to use.

acme.sh is the most simple client that I found, but their default usage
instructions still do some magic that I would rather avoid, so I'll
present here my modified installation method, which doesn't have any
magic and where you're fully in control of every step.

### Setting up a restricted user

We'll do a custom installation of [acme.sh](https://github.com/acmesh-official/acme.sh)
so that it runs **with its own restricted user** based on [this Gist](https://gist.github.com/lachesis/943769f3fac740d5848352752ac08741),
because running it as root like they show out of the box is
irresponsible.

First we create a `acme` user with home directory set to `/var/lib/acme`
(it'll be created automatically because we specified `-m`) and
`/usr/sbin/nologin` as login shell to deny login access to this account.

```sh
useradd -m -d /var/lib/acme -s /usr/sbin/nologin acme
```

We also make sure this home directory is only accessible by the `acme`
user itself.

```sh
chmod 700 /var/lib/acme
```

Then we prepare the webroot challenge directory that we configured
earlier in `nginx.conf`. We make sure that it's owned by the `acme` user
and group so that it can write to this directory. The default permission
for the directory is full access for the user and read and execute
access for everyone else which is fine here.

```sh
mkdir /var/www/challenges
chown acme:acme /var/www/challenges
```

Next, we prepare the directory where we'll install the certificates.
This directory needs to be writable by the `acme` user but nginx (who
runs under the `www-data` user and group) needs to be able to read from
it, so we set the group to `www-data`.

This allows us to set the `710` permission which means full access for
the user, execute access for the group (on a directory that means it can
access files in this directory according to the files permissions but
cannot list the contents of the directory), and no permissions for
everyone else.

```sh
mkdir /etc/acme
chown acme:www-data /etc/acme
chmod 710 /etc/acme
```

Finally we give `sudo` access to the `acme` user, allowing it to only
run the `/bin/systemctl reload nginx` command without being prompted for
a password. Run `visudo` to safely edit the `/etc/sudoers` file and add
the following line:

```sh
acme	ALL=(ALL:ALL) NOPASSWD: /bin/systemctl reload nginx
```

We can now open a shell as the `acme` user to set up acme.sh there. Here
we explicitly precise `/bin/bash` as shell because we set the default
one to `/usr/sbin/nologin` for this user earlier to deny shell access.
We make sure to run a login shell using `-`.

```sh
su -s /bin/bash - acme
```

We'll end up in the home directory which we set earlier to `/var/lib/acme`.

### Installation

We can now follow the official [install from Git instructions](https://github.com/acmesh-official/acme.sh#2-or-install-from-git)
because piping scripts from the web into `sh` is a terrible idea.

```sh
git clone https://github.com/acmesh-official/acme.sh
cd acme.sh
```

That's where my method starts to differ. They recommend running
`./acme.sh --install -m my@example.com` which will do a number of
things:

1. Register to [ZeroSSL](https://zerossl.com/) with the given email address.
1. Copy the contents of the repo to `~/.acme.sh`, doing a few shebang
   modifications.
1. Create a default `account.conf` and `acme.sh.env` files that we won't
   need here.
1. Generate a cron entry to renew certificates, which we can generate
   later on with a more specific command.

I like to keep the source code separate from the configuration and some
of those steps are unnecessary for me.

Instead, I don't "install" acme.sh and I just run it from its Git repo,
which will make it much easier to update the code in the future. Because
by default it stores all the configuration in `~/.acme.sh`, this has the
nice side effect of keeping the code and the configuration separate. The
code from the repo is directly usable, and all the extra state will be
put in `~/.acme.sh`.

We still need to explicitly register to ZeroSSL (or any of the other
[supported certificate authorities](https://github.com/acmesh-official/acme.sh#supported-ca)):

```sh
./acme.sh --register-account -m y@example.com
```

We also need to set up the cron entry:

```sh
LE_WORKING_DIR=$PWD ./acme.sh --install-cronjob
```

You can check what acme.sh did by running `crontab -l`. You could also
manually configure an entry like:

```crontab
42 0 * * * /path/to/.acme.sh/acme.sh --cron --home /path/to/.acme.sh > /dev/null
```

This would run the acme.sh cron task every day at 00:42. But their
`--install-cronjob` script generates a random minute to run the job so
that the certificate authority doesn't get a huge burst of requests at
the same second every day, which I think is a good practice to keep.

From there, the commands we'll run are the same as the recommended ones
in the acme.sh readme.

## Preparing the certificates directory and DH parameters

I like to install my certificates in `/etc/acme` which we created
earlier, with a directory per domain, but this is totally arbitrary.

```sh
mkdir /etc/acme/codejam.info
```

We also get the <abbr title="Diffie-Hellman">DH</abbr> parameters as
recommended by [Mozilla's SSL configuration generator](https://ssl-config.mozilla.org/).

```sh
curl https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/acme/ssl-dhparams.pem
```

<div class="note">

**Note:** long story short, generating strong DH parameters is not that
easy and it's actually [considered more secure](https://security.stackexchange.com/a/149818)
to use ones that are proven to be strong despite being public like those
provided by Mozilla, unless the key size is considered short (1024 bits
or less as of today's standards), then using shared DH parameters could
introduce more security risks than it would prevent.

</div>

### Generating our certificate

```sh
./acme.sh --issue -d codejam.info -d www.codejam.info -w /var/www/challenges
```

This will issue a certificate for `codejam.info` with `www.codejam.info`
as alternate name (you can put as many alternate names as you want with
subsequent `-d` parameters), meaning that the certificate will be valid
for all of those domains. You can also generate a wildcard certificate
but this requires going through automated DNS validation which I won't
cover in this blog post.

### Installing the certificate

In the previous step, acme.sh generated the key and certificate files in
its own state directory, but it's not recommended to hardcode those
paths. That's why we configure certificate installation paths as well as
a reload command:

```sh
./acme.sh --install-cert -d codejam.info \
    --key-file /etc/acme/codejam.info/privkey.pem \
    --cert-file /etc/acme/codejam.info/cert.pem \
    --fullchain-file /etc/acme/codejam.info/fullchain.pem \
    --ca-file /etc/acme/codejam.info/chain.pem \
    --reloadcmd 'sudo systemctl reload nginx'
```

This will not only install the files in the specified locations and run
the reload command, but will also save those to your domain
configuration so that acme.sh knows knows where to install the
certificates and how to reload the server during the cron job.

But we commented out the certificate files in `nginx.conf` earlier
because they didn't exist yet. We can now edit the config (as root) to
reference those files we just installed.

```diff
-# ssl_certificate /path/to/signed_cert_plus_intermediates;
-# ssl_certificate_key /path/to/private_key;
+ssl_certificate /etc/acme/codejam.info/fullchain.pem;
+ssl_certificate_key /etc/acme/codejam.info/privkey.pem;
 ssl_session_timeout 1d;
 ssl_session_cache shared:MozSSL:10m;
 ssl_session_tickets off;
-# ssl_dhparam /path/to/dhparam;
+ssl_dhparam /etc/acme/ssl-dhparams.pem;
 ssl_protocols TLSv1.2 TLSv1.3;
 ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
 ssl_prefer_server_ciphers off;
 add_header Strict-Transport-Security "max-age=63072000" always;
 ssl_stapling on;
 ssl_stapling_verify on;
-# ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates;
+ssl_trusted_certificate /etc/acme/codejam.info/chain.pem;
```

Verify the config is valid with `nginx -t` and run a final `systemctl
reload nginx` to apply the changes.

## Bonus: HTTP basic authentication

You don't want your website to be public just yet but still want to test
it from there? Add basic authentication to it!

```sh
apt install apache2-utils
htpasswd -c /etc/nginx/htpasswd <user>
```

Then in `nginx.conf`, add the following to the `server` block you want
to add authentication to:

```nginx
location / {
    auth_basic "Private";
    auth_basic_user_file /etc/nginx/htpasswd;
}
```

Here, "private" is the [basic authentication `realm` parameter](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate#directives)
and could be literally anything. It doesn't even seem to be shown in
browser UIs anymore so it doesn't really matter.

## Wrapping up

At that point, you should have a working HTTPS server with auto-renewed
certificates. I hope this post was useful to you!

<div class="note">

**Note:** if you're looking to integrate Let's Encrypt or similar on
your server but this post was too technical for you, [let me know](/val.md#links),
I'm available for [contracting](/resources/freelance.md) projects and
I'll be happy to help you with that. ✌️

</div>
