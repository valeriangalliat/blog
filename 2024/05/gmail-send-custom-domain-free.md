---
tweet: https://twitter.com/valeriangalliat/status/1786553405659545823
---

# Use Gmail to send emails with a custom domain for free (secret trick) 😏
May 3, 2024

So you want to use Gmail with a custom domain without paying a Google
Workspace subscription? Well, it's possible!

The main tradeoff with that is that Gmail will
[display](https://support.google.com/mail/answer/1311182)
your emails on the recipient side with a "via gmail.com" next to your
email.

<figure class="center">
  <img alt="Sender card showing &quot;via gmail.com&quot;" srcset="../../img/2024/04/gmail/via.png 2x">
</figure>

The second tradeoff is that while the email will appear with your custom
domain, the Gmail address that you use will also show in the source
headers of the email, so a technical user could find it.

The last tradeoff is that you won't be able to sign your emails with
DKIM.

If you're fine with that, then read on!

## Configuring Gmail SMTP as an external SMTP in Gmail 🙃

Gmail allows you to add external SMTP servers, to send emails using
other email addresses that you own. You can find that in **Settings >
Accounts and Import > Send mail as**.

However, Gmail can itself be used as a SMTP server for _other apps_ to
send emails via your Gmail account. That in itself is a bit of a hidden
trick, and is explained [here](https://noted.lol/setup-gmail-smtp-sending-2023/).

In short: [in your Google account security settings](https://myaccount.google.com/security),
in **2-Step Verification > App passwords**, add a new app password.

<figure class="center">
  <img alt="App passwords" srcset="../../img/2024/04/gmail/app-passwords.png 2x">
</figure>

<div class="note">

**Note:** that section may not show for you... on my side it seems to
show only if I already have existing app passwords but it's completely
missing otherwise!

Luckily you can still access it via its [direct URL](https://myaccount.google.com/apppasswords).

</div>


Then you can use the following SMTP settings:

```
Host: smtp.gmail.com
Port: 587
Encryption: TLS
User: you@gmail.com
Password: the password generated earlier
```

Where it gets funky is that you can use those SMTP settings from inside
Gmail itself, like if you were adding an external SMTP server!

Again, in **Settings > Accounts and Import > Send mail as**, you can
**Add another email address**. Use your custom email address in the
email field e.g. `you@yourdomain.com`. Then use the SMTP settings from
above. In the SMTP settings, the user needs to be your Gmail account,
e.g. `you@gmail.com`, and not `you@yourdomain.com`.

Gmail will then need to verify that you own that email by sending you a
confirmation email. Once the verification done, you can start sending
emails using your custom domain! (You may have to reload the page as I
did otherwise sending an email using the new address would hang
forever.)

## Why is that even allowed?

It's nice that Gmail does that verification step to confirm you do
really own that address, because they definitely don't want Gmail
servers to be used to send nonlegitimate emails. But not all providers
and SMTP servers are that cautious. If I can make Gmail servers send
emails on the behalf of my domain, what prevents anyone to do the same
with their own servers?

Well, I'm glad you asked. Turns out anyone can, unless you configure
DKIM and DMARC.

### DKIM & DMARC

With DKIM, you generate a keypair, configure the private key on your
SMTP server to sign your emails, and configure the public key on your
DNS so that the servers receiving your emails can check the signature
against your public key.

DMARC is also configured on your DNS and lets you define rules about how
to deal with emails that don't pass DKIM validation (ignore, mark as
spam, or block), as well as endpoints to receive reports (so you have a
way to know if you misconfigured something and your emails are getting
blocked).

### You need Google Workspace for that

However as I mentioned in the beginning, that nifty Gmail setup doesn't
let you use DKIM. You can't configure a private key on Gmail's SMTP
servers for them to sign emails from your custom domain. That's a Google
Workspace [feature](https://support.google.com/a/answer/180504) that you
have to pay for.

So for this trick to work, you need to not have DMARC configured, or
have your DMARC configuration allow unsigned emails.

### What about SPF?

Interestingly, SPF doesn't help with that situation, because it
[acts on the `Return-Path`](https://postmarkapp.com/guides/spf#understanding-the-limitations-of-spf)
and not the `From` header.

In the case of the Gmail setup above, the email headers would look like:

```
From: you@yourdomain.com
Return-Path: you@gmail.com
```

(As I mentioned above, that's where the Gmail email appears in the
source and could be seen by technical users.)

SPF validates against the `Return-Path`, so it will check that the
server sending the email is indeed allowed to send emails on behalf of
`gmail.com`, which Gmail servers are. No fucks are given about
`yourdomain.com` at that point.

Because of this weakness in SPF, that's why even if SPF validation
passes, Gmail displays the "via" label when the `From` and `Return-Path`
domains don't match [and the email is not signed with DKIM](https://postmarkapp.com/blog/dkim-and-the-via-label-in-gmail).
This gives you a chance to know that the email is not authenticated and
sent through a third party.

## It doesn't work across Gmail accounts

One thing to note, which you're probably not likely to run into, but
well, I do weird things sometimes, is that this setup _doesn't work
across different Gmail accounts_.

By that, I mean that if you set up an "app password" on `you2@gmail.com`,
and you configure it as the outbound SMTP server for `you@gmail.com` to
send emails from `you@yourdomain.com`, **it won't work**.

Your emails will be sent, but it won't show the custom email domain, it
will show from `you2@gmail.com` instead. The trick only works when the
same Gmail account is used in both places.

If this section makes no sense to you, don't worry about it. It's quite
a niche setup to try, but I thought I'd mention anyway if it can be
useful to anyone trying to do the same thing.

## Wrapping up

I hope this trick will be useful to you!

As far as I'm concerned, because I wanted to avoid the "via" label and I
wanted to be able to set up DKIM, I went with [Zoho Mail](https://www.zoho.com/mail/)
(not affiliated). They try really hard to hide it, but they
[actually](https://help.zoho.com/portal/en/community/topic/free-plan-mail-accounts-details)
have a [free plan](https://www.zoho.com/mail/help/adminconsole/subscription.html#:~:text=under%20Zoho%20Workplace-,free%20plan,-%3A%20Using%20this%20plan)
with up to 5 GB of storage, which I don't care about because I just
configure it as an outbound SMTP server that doesn't store anything. 😄

Either way, you should now be all set to send emails with your own
domain. Enjoy! 🤙
