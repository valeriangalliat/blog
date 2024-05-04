---
tweet: https://twitter.com/valeriangalliat/status/1629899238728499200
---

# OVH email redirect causes SPF check failure
February 26, 2023

<div class="note">

**Note:** I put OVH in the title but it could happen with any provider
that offers email redirects.

</div>

Let's say you have an email address `foo@foo.com`, and you set up a
redirect with your provider so that it forwards all emails to
`foo@gmail.com`, which would be a common scenario to use Gmail with a
custom domain without paying for Google Workspace (using this as an
example but the problem is not directly related to Gmail).

In my case with OVH, this is configured in `foo@foo.com`'s MX plan,
under [manage redirections](https://docs.ovh.com/ca/en/emails/email-redirection-guide/).

It works well most of the time, **except when a sender tells me they
failed to send me an email**.

It could be someone sending me an email from, for example,
`bar@gmx.com`, who tells me (obviously via another mean) that their
email was returned, with a message similar to this:

> **Subject:** Undelivered Mail Returned to Sender  
> **From:** `MAILER-DAEMON@mo557.mail-out.ovh.net`
>
> This is the mail system at host `mo557.mail-out.ovh.net`.
>
> I'm sorry to have to inform you that your message could not be
> delivered to one or more recipients. It's attached below.
>
> For further assistance, please send mail to postmaster.
>
> If you do so, please include this problem report. You can delete your
> own text from the attached returned message.
>
> The mail system
>
> <foo@gmail.com>: host gmail-smtp-in.l.google.com[66.102.1.27] said:
> 550-5.7.26 The MAIL FROM domain [gmx.com] has an SPF record with a
> hard fail 550-5.7.26 policy (-all) but it fails to pass SPF checks
> with the ip: 550-5.7.26 [46.105.33.1]. To best protect our users from
> spam and phishing, the 550-5.7.26 message has been blocked. Please
> visit 550-5.7.26 https://support.google.com/mail/answer/81126#authentication
> for more 550 5.7.26 information.
> h21-20020a05600c351500b003eb3caa4d08si2037016wmq.38 - gsmtp (in reply
> to end of DATA command)

<div class="note">

**Note:** I use [GMX](https://www.gmx.com/) as an example here because
it's a sender domain that I was consistently getting SPF issues with
because of my redirect setup.

</div>

This doesn't seem to be a very widely encountered problem, yet I could
find a few occurrences of it in the wild like on [this Reddit post](https://www.reddit.com/r/AnonAddy/comments/ju9vgc/ovh_mail_redirection_fails/)
as well as those Google
[support](https://support.google.com/mail/thread/175932116)
[threads](https://support.google.com/mail/thread/195729241)
(in French, and sadly locked so I couldn't post the solution there).

## The issue

What's going wrong here? It turns out that the sender domain (in this
example, `gmx.com`) had configured a strict [SPF policy](https://en.wikipedia.org/wiki/Sender_Policy_Framework)
that only allowed their own servers to deliver emails from `@gmx.com`
addresses.

We can check this running the following command:

```console
$ host -t TXT gmx.com | grep spf
gmx.com descriptive text "v=spf1 ip4:213.165.64.0/23 ip4:74.208.5.64/26 ip4:74.208.122.0/26 ip4:212.227.126.128/25 ip4:212.227.15.0/24 ip4:212.227.17.0/27 ip4:74.208.4.192/26 ip4:82.165.159.0/24 ip4:217.72.207.0/27 -all"
```

<div class="note">

**Note:** to be clear, this is not a bad thing. It's totally legitimate
from GMX to only allow their own servers to deliver emails from
`@gmx.com` addresses!

The reason it doesn't happen with most sender domains is that it's
common to configure SPF with a "soft fail" (`~all`) instead of a "hard
fail" (`-all`) like GMX does. See the difference [here](https://knowledge.ondmarc.redsift.com/en/articles/1148885-spf-hard-fail-vs-spf-soft-fail).

A soft fail would result in the email being delivered but potentially
being flagged as spam, whereas a hard fail gets downright rejected.

</div>

Since Gmail do check the origin sender SPF policy and enforces it, it
rejected the `@gmx.com` email being forwarded by my OVH relay.

If you want to learn more about this issue, [this post from Tiger Technologies](https://support.tigertech.net/spf)
is a very good read.

## Use Cloudflare!

<div class="note">

**Note:** section added on April 27, 2024.

</div>

Since writing this post, I transferred my domain to Cloudflare. For
multiple reasons. On of them was related to this email routing issue!

Cloudflare [goes further](https://community.cloudflare.com/t/email-routing-and-spf/341490)
than OVH in that regard:

> Cloudflare rewrites the `Return-Path` to be your own domain, which is
> what SPF is checked against (it's not checked against the friendly
> `From`, as most people believe).

This is genius! It means that if `bar@gmx.com` sends you an email to
`foo@foo.com` (configured on Cloudflare to redirect to `foo@gmail.com`),
Cloudflare will rewrite the email headers with a `Return-Path` of
`gmx.com=bar@foo.com`. Because you own `foo.com`, you can allow
Cloudflare servers in your SPF policy, and the email does not get
blocked!

And the actual email in the `From` header is the one that gets shown on
your email client, so it looks totally transparent.

The redirected email still passes DKIM signature verification since the
`Return-Path` is typically not included in the headers used to compute
the DKIM signature, so it can be freely altered.

The only non-transparent thing is if the original email does _not_ have
a DKIM signature. Then that's where clients like Gmail [show a "via" domain](https://support.google.com/mail/answer/1311182)
next to the sender's name.

For example if the sender uses the
[trick to use Gmail SMTP to send mails with a custom domain](../../2024/05/gmail-send-custom-domain-free.md),
they have no means to configure a DKIM signature, and the recipient will
see it as from "Sender's Name via gmail.com".

In that case, if as the recipient, you're using Cloudflare email
redirects, then it will show up as "Sender's Name via
cloudflare-email.net" instead.

A bit of an edge case, but something to know.

## The fix without changing providers

If your existing email redirect provider is not as smooth as Cloudflare
and you're not willing to move, then what's left?

Well in my case, I had to reverse the relationship between my OVH
address and Gmail: instead of my OVH address forwarding emails to Gmail,
I removed the redirect and **configured Gmail to fetch emails from my
OVH address via POP3**.

<div class="note">

**Note:** this alternative method is not specific to OVH and Gmail. It
will work as long as:

1. Your target email system supports fetching emails from other
   addresses via IMAP or POP3.
2. The email hosting provider you use for your intermediary address
   has IMAP or POP3 capabilities, not only redirects.

</div>

In order to do this with Gmail, their guide on [checking emails from other accounts](https://support.google.com/mail/answer/21289).

And if your intermediary (redirect) address is on OVH, you can find the
proper POP3 settings to use on their configuration guide, either for
[OVH France](https://docs.ovh.com/fr/emails/mail-mutualise-guide-configuration-dun-e-mail-mutualise-ovh-sur-linterface-de-gmail/) or
[OVH Canada](https://docs.ovh.com/ca/en/emails/gmail-configuration/). In
short, it's:

| Region | Host              | Port |
|--------|-------------------|------|
| France | `ssl0.ovh.net`    | 995  |
| Canada | `pop.mail.ovh.ca` | 995  |

## The downside

The main downside of this solution is that instead of OVH _pushing_
mails to Gmail, Gmail has to _pull_ them from OVH periodically.
Concretely, this means **increased latency**. Instead of receiving
emails right away, you'll have to wait until Gmail decides to fetch
emails from your external accounts.

There's no clear rule on how often Gmail checks external accounts. It
seems to be proportional to how often you receive new emails: if you
often receive new emails, it'll check quite often, but if you receive
just a few messages per day, **it can wait 10, 20 or even 30 minutes
between refreshes**.

## Forcing Gmail to refresh external accounts more often

Looking into this I found quite a few smart tricks to get Gmail to check
your external accounts more often.

The first one is [described in this post](https://rakowski.pro/how-to-force-gmail-to-check-your-pop3-account-as-often-as-possible/),
and consists in configuring a server of yours to send you an email (on the
address you check via POP3) every minute or so. This way, Gmail will
notice you're getting a lot of messages and will check more often.

To avoid your inbox getting flooded by those messages, you can simply
add a filter that puts them directly to the trash!

What if you don't have a server handy to run this script? As described
in this [Lifehacker post](https://lifehacker.com/increase-the-frequency-gmail-checks-your-other-email-ac-5580553),
you can run the code as Google Apps Script on Google Sheets. That's
pretty rad if you ask me. 😂

But what if you don't want to write code at all? [This Stack Exchange comment](https://webapps.stackexchange.com/questions/1811/can-i-control-how-often-gmail-polls-pop3-accounts-for-incoming-mail#comment2919_2090)
got you covered: just create a dummy Google Calendar event repeated every X
minutes, and set up an email reminder for this event. 🤯

## The hybrid approach

With OVH, there's another option that allows you have the speed of the
redirect when it works, but still receive the messages even when there's
an SPF rejection. The problem of this approach is that it will still
result in the "Undelivered Mail Returned to Sender" message being sent
to the sender in case SPF fails (even if you do get the email), which is
not ideal.

This solution consists in the OVH email redirect settings to "keep a
copy of the email at OVHcloud". This option is only available during the
initial redirect creation and can't be modified later on, so if you
initially configured it as "do not store a copy of the email", you'll
need to delete your redirect and recreate it.

<div class="note">

**Note:** creating a redirect that keeps a copy of the email on OVH
materializes as two redirect entries: one from source to source, and one from
source to destination.

For example, it'll show:

* `foo@foo.com` to `foo@gmail.com`
* `foo@foo.com` to `foo@foo.com`

Just noting that here because it can be confusing.

</div>

On top of that, you also configure Gmail to check your OVH emails via
POP3 [as explained earlier](#the-fix).

The result is that when the redirect works, you'll get your emails
instantly. When case the redirect fails, the message will still end up in
your OVH inbox, which Gmail will fetch eventually, so you'll still get
it that way.

But as I said, because the redirect failed, the sender will still
receive back an error email and believe that you didn't receive their
email. I don't know of a way to avoid that with this solution.

As for the messages that were successfully redirected, be assured that
_they won't be duplicated_! Even though they will be fetched again when
Gmail refreshes the POP3 inbox, Gmail is able to tell that it's the same
message that it already saw and will not show it to you twice. Neat.

## Wrapping up

In this post we explored the technical details of a common error that
happens when an email redirect conflicts with the origin SPF rules.

We saw that we can mitigate it under certain conditions, by reversing
the redirect relationship: instead of one email redirecting to another,
you need to have the second email checks the inbox of the former.

With Gmail, this can introduce unwanted latency, but there's a few hacks
to work around that.

Finally we saw an hybrid approach that gets "the best of both worlds",
except for the error message still being sent back...

What was your favorite option? Let me know on
[Twitter](https://twitter.com/valeriangalliat/status/1629899238728499200)!

And if you know of other solutions I didn't mention, please send me an
email! Even if you do strict SPF checks, don't worry, I'll receive it. 😉
