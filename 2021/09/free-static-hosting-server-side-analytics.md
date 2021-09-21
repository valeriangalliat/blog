# Free static hosting with server-side analytics
Comparing GitHub Pages, Netlify, Cloudflare, Google Cloud and Vercel  
September 21, 2021

This blog has been hosted on [GitHub Pages](https://pages.github.com/)
for a while, but I was getting frustrated of not having any idea of the
traffic it was getting, and I was really curious to find out.

The only way to get traffic insights on GitHub pages is through
client-side analytics scripts, which is technically very unreliable, and
I'd rather not get any data than getting data that I cannot trust, and
which on top of that negatively impacts the performance of my site.

What I want is raw access to HTTP logs, which is the only proper source
of truth for this.

In the first part of this series, I'll compare different free static
hosting services and their options to get access to server-side
analytics or logs. Then, I'll show you [in the second part](vercel-custom-log-drain.md)
how to retrieve logs on a Vercel app, which is the only service I found
to provide HTTP logs as part of their free offer!

## GitHub Pages

[GitHub Pages](https://pages.github.com/) is the easiest option to host
a static website for free, especially if you're already working with
GitHub, but it doesn't have an option to access HTTP logs.

The only method they document is using Google Analytics or a similar
script, but that's not an acceptable solution to me. Let's move on.

## Netlify

[Netlify](https://www.netlify.com/) is my next favorite way to deploy a
static website. They also have a [Netlify Analytics](https://www.netlify.com/products/analytics/),
product, an analytics platform based on server logs, which is exactly
what I want!

As they point out in their marketing page, it's "data right from the
source of truth", it's got "better performance", "more accurate
numbers", "better privacy" and gives you access to extra metrics you can
only get on the server side.

To me this the only proper way to get traffic analytics on the web.

But they price that feature at $9 per month per site, which to be honest
is pretty decent if you have a website that's generating some cash, but
my blog is not and my current budget is closer to $0.

## Cloudflare

[Cloudflare](https://www.cloudflare.com/) also has a free static hosting
offer. They've got a [Cloudflare Analytics](https://www.cloudflare.com/web-analytics/)
product, but the free version is only powered by a client-side script,
which as we saw earlier, is useless.

Otherwise, the option to have analytics based on server logs starts with
the "pro" plan that's $20 per month. Too much for me.

They also offer [Cloudflare Logs](https://www.cloudflare.com/products/cloudflare-logs/)
which seems like it would at least give access to raw HTTP logs, but the
pricing is not mentioned and you need to contact their sales department
to maybe get access to it. Doesn't look good.

## Render

[Render](https://render.com/) is another service with free static
hosting, and a it's a very well built product. Simple and efficient. Out
of all the websites in this list, it's the one with my favorite UI so
far. Gets shit done, no bullshit. 😍

I especially love the fact that they allow to configure any public Git
URL to pull from, without forcing you to connect with GitHub or another
hosted Git provider through OAuth like it's the case with [Vercel](#vercel).

Sadly, while you can [configure a syslog drain](https://render.com/docs/log-streams),
it only forward application logs and doesn't include edge load balancer
HTTP logs, which is the only thing I care about.

## Google Cloud free tier VM

While it's very different from the other managed services I mention in
this list, [Google Cloud](https://cloud.google.com/free/docs/gcp-free-tier/#compute)
allows you to run a `e2-micro` instance constantly for free.

The `e2-micro` instance has access to 0.25 vCPU and can burst up to 2
vCPUs. It's got 1 GB of RAM, and you're allowed up to 30 GB of storage
for free. You can even assign it a static IP that will stay free as long
as it's in use.

It's a pretty underpowered machine but will be way fine for serving
static websites, for example with nginx, as long as it doesn't have a
ridiculous amount of traffic.

The only caveat is that you still have to [pay for traffic](https://cloud.google.com/vpc/network-pricing).

Ingress traffic is free (data going in the VM), but you'll have to pay
for egress traffic (data going out of the VM). In other words, this
means that someone uploading a large file to your VM will be nearly
free, but serving a large file to someone will impact your billing.

Typically this is low enough to be negligible, but Google will be happy
to charge your credit card for $0.03 every month.

And because *you're the server*, you can do whatever the fuck you want,
like logging HTTP traffic to `/var/log`.

This solution requires a bit of system administration knowledge, but if
like me, you find it to be exciting and a lot of fun, it's definitely a
good solution. That being said you'll also be responsible of managing
the VM, keeping it up-to-date, and fixing any issue that might happen
with it, otherwise you website might get some downtime.

## Vercel

Finally, [Vercel](https://vercel.com/) also has free static hosting. Yay!

They even have a [Vercel Analytics](https://vercel.com/analytics)
product, but it's mostly focused on performance, and the data is
captured on the client side. Makes sense for performance data, but not
what I want.

They also have [logs](https://vercel.com/docs/deployments/logs), which
can even be [persisted](https://vercel.com/docs/deployments/logs#persistence),
through [logging integrations](https://vercel.com/integrations#logging).

This is great, but the whole point I'm doing this comparison is because
I want a *free* hosting with logs. If I'm not willing to pay for
hosting, I'm not going to pay for Logtrail, Sematext, Datadog or LogDNA. 😆

The good news is that the logging integrations are built on top of [log
drains](https://vercel.com/docs/rest-api#integrations/log-drains), and
Vercel allows to [create custom integrations](https://vercel.com/docs/integrations).
This means that we can create our own custom integration, and for
example, configure a log drain that forwards the logs to... a [Google Cloud free tier VM](#google-cloud-free-tier-vm)!

This is the best of both words, because Google Cloud won't charge for
ingress (and sending data to it is indeed ingress), so we'll only pay
for the egress of our SSH session where we query the log files, but
that's going to be negligible.

In [the next post](vercel-custom-log-drain.md), I'll show you how to set
up Vercel with a custom integration to forward logs to a Google Cloud VM
(or the log drain of your choice). See you there!
