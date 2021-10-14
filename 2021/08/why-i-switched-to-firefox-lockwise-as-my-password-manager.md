# Why I switched to Firefox Lockwise as my password manager
August 8, 2021

First thing first, the purpose of this article is not to convince you to
do the same. I just like to document the reasoning behind some of my
choices, because I think it can be interesting. If you're curious about
this, read on!

Also, this post is not going to be about *why you should use a password
manager* in the first place. But you should probably use a password
manager, and in case you don't, I'll write a quick section about that.
Feel free to [skip it](#why-firefox-lockwise)!

## Why you should use a password manager

* Passwords are the most widespread way of authentication to websites
  and other services on the internet.
* The average user tends to log in [on over a hundred services](https://blog.dashlane.com/world-password-day/),
  and it's only going to grow over time.

This brings a number of challenges that are addressed by some common
ways of dealing with passwords, some worst than others, which I'll go
through below.

### Using a single password

If you use the same password everywhere, would a single of the services
you signed up with have a security issue, that allows an attacker to
gain access to your password, and all of your other accounts sharing
that password can be considered compromised. Not great.

Using a different password everywhere mitigates that, but it's not
scalable for most of us to remember hundreds of different passwords.

### Deriving a password

A common solution that people found to help with this was to *derive* a
primary password for each service. Typically, since most people can't
perform [HKDF](https://en.wikipedia.org/wiki/HKDF) or
[PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) mentally, we tend to just
prepend or append the base password to the website name or something
similar.

This is only an illusion of security and it's fairly easy for an
attacker with access to one of your "unique" passwords to guess in a
limited number of tries the corresponding passwords to other websites.

### Using OAuth

[OAuth](https://en.wikipedia.org/wiki/OAuth), e.g. "sign in with Google
/ Apple / Twitter / Facebook / GitHub" is another common way to
authenticate to services, and is a solid alternative to passwords in a
lot of cases, but it is limited to the support of the websites you're
trying to access.

For example, while your local grocery store might allow you to sign in
with Google, or the latest trending project with a .io domain probably
allows you to sign in with GitHub, it would be very weird if Apple /
Twitter / Facebook allowed you to sign in with Google, or any possible
combinations among them, meaning that you'll need a different password
at least for all of those. And anyways, a lot of services just don't
support OAuth whatsoever meaning you'll need unique passwords for them
too.

In practice, OAuth is useful, but doesn't solve the problem.

### Using a password manager

A password manager takes away from you the responsibility of remembering
passwords. This means that it's now easy to have a strong, unique
password for every account you have. The only password you need to
remember is now the one of your password manager (unless it uses a
different kind of authentication).

While you can import your existing (potentially weak, because you had to
remember them) passwords, moving to a password manager is also a good
opportunity to replace them with strong, randomly generated passwords.

The downside is that the primary password you choose for your password
manager becomes a single point of failure. If it is compromised, all
your passwords are compromised.

There's a [great thread on Stack Exchange](https://security.stackexchange.com/questions/152269/a-password-manager-a-single-point-of-failure-then-why-is-it-so-often-recommende)
about the tradeoffs of password managers.

Still, to mitigate that, I would recommend using a passphrase instead of
a password, as pointed out by [this legendary xkcd](https://xkcd.com/936/).

<figure class="center">
  <a href="https://xkcd.com/936/">
    <img alt="Passphrases vs. passwords" src="https://imgs.xkcd.com/comics/password_strength.png">
  </a>
</figure>

## Why Firefox Lockwise

Now we're on the same page about using a password manager (or not),
let's see why I, personally, chose to move to Lockwise.

But before digging in what's good or not about it, let me give a bit of
context about the way I use a password manager.

* I'm primarily a desktop (and laptop) user. I barely use my phone for
  anything else than texting.
* For the rare times I use my phone for something else, I want to be
  able to easily access my passwords, and login to *existing* accounts
  in the browser (I use Firefox for Android) and native apps.
* I use Firefox passwords autosave/autofill feature (offline) as a
  companion to my current CLI password manager. I want to keep at least
  the same level of convenience, and ideally a better integration.
* I need my password manager to be open source. If I can't review the
  code that's going to deal with my passwords, I can't trust it.
* I currently don't pay for any subscription other than my ISP and
  mobile carrier, and I'd like to keep things this way.

<div class="note">

**Fun fact!** Before that, I was using my own password manager which was
just a tiny layer of (desktop-only) convenience over Git, PBKDF2 and
AES-256. While it could have worked on mobile, I was lazy to build an
app for it and decided it was time to change.

</div>

## Pros

Let's start with the pros of Firefox Lockwise. Sadly, there's not a lot,
but their impact is so big for me that they make all the difference.

### It's native to Firefox

Lockwise is not a browser extension, it's directly baked in Firefox
itself. This means that it is not limited to a browser extension sandbox
like third-party password managers. It's basically just a cool name for
Firefox's native passwords autofill engine, and the `passwords`
collection of Firefox Sync.

This has the advantage of allowing for a super smooth user experience
(at least for the happy path it was designed for). It pretty much always
does the right thing at the right time when it's about filling login
forms, or asking to save new login information.

For comparison, when I was using Bitwarden (which to be honest, I find
superior in all other aspects), the experience wasn't as seamless. Quite
often I wouldn't be prompted to save new passwords, and I had to go in
the extension UI to add them manually, or it would fail to fill a login
form for which it had matching credentials, making me open the extension
to explicitly ask it to fill out the boxes. I think most of those issues
weren't necessarily "poor quality" from Bitwarden, but more due to the
fact it's limited to a browser extension sandbox, and cannot get the
same level of integration than the browser engine itself.

Because the happy path Lockwise was designed for overlaps so much with
my own usage (which might not be the case of everybody), this makes it a
great fit for me, compared to Bitwarden, which doesn't perform as well
on my main use case, but does a better job at pretty much everything
else.

In other words, Lockwise is great 95% the time I use it, but sucks at
the remaining 5%, while Bitwarden is just consistently good (but not
great).

### It's part of Firefox Sync

As I mentioned in the previous part, Lockwise is built on top of Firefox
Sync, which happens to be the tool I use to synchronise my tabs and
bookmarks between all my devices.

At that point it seems like an obvious solution to also use it for
my passwords. After all, if the tool I'm already using fits my needs,
why try to add another one?

## Cons

Now as of today, Lockwise is missing a number of features one would
expect from a password manager, some of them being being so basic that
it can look pretty ridiculous.

### No extension for other browsers

Lockwise is part of Firefox, but there's no integration with other
browsers. If Firefox isn't your primary browser, you're probably not
reading this anyways, but if you need to have convenient access to your
passwords in another browser, Lockwise is definitely not for you.

You can obviously still open Lockwise in Firefox and copy passwords to
your clipboard to use them anywhere, but in no way this can compete with
a proper integration.

### Can't generate new passwords on mobile

From the mobile version of Firefox, we can't generate new passwords.
Neither can we from the Lockwise standalone mobile app.

If we submit a login form with a new password that we manually typed,
both Firefox and the Lockwise app will happily ask us if we want to
update an existing entry or save a new entry, but we just don't have the
option to "suggest a strong password" like the desktop version does.

This is probably a dealbreaker for a lot of people, unless you only use
your phone a negligible part of the time like I do, and mostly as a
read-only client as far as for passwords are concerned.

### The mobile app crashes regularly

While Firefox for Android works flawlessly for me, the Lockwise app
crashes pretty often (something as simple as trying to edit an entry
from the app). Since Firefox also have a UI to manage (synced)
passwords, I use that instead. It's not something I need to do really
often on mobile anyways, if ever really.

The only reason I have the Lockwise app installed is to be able to
autofill a password in other native apps, and it does a good job at
this.

### No TOTP support

[TOTP](https://en.wikipedia.org/wiki/Time-based_One-Time_Password)
(time-based one-time password) is a common mechanism to provide
[multi-factor authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication)
through authenticator apps. If you're new to the concept, it's
essentially a second password that is randomly generated by the issuing
service during setup, that you store in the authenticator app of your
choice, usually through a QR code.

When you later login on that service, on top of your actual password,
they'll request a confirmation code. Your authenticator app can use the
key that was configured during setup, together with the current time,
rounded down to the closest 30 seconds (or as configured otherwise) to
[generate](https://en.wikipedia.org/wiki/HMAC) a short code that the
service will be able to verify only for that period of time.

It's a common feature for password managers to support acting as a TOTP
authenticator, and [this post](https://jamesrcridland.medium.com/should-you-store-your-2fa-totp-tokens-in-your-password-manager-9798199b728)
explains better than me why it's a good thing. Sadly Lockwise doesn't
support it.

While I would love TOTP support, it's not a critical-enough feature for
me to trade off the quality of experience I otherwise have with Lockwise
to move to Bitwarden.

It's especially not a big deal for me because I already have my own
"authenticator app" based on [totp-generator](https://www.npmjs.com/package/totp-generator),
and I can [hack my way around](../09/totp-2fa-support-any-password-manager.md)
storing the TOTP secrets in Lockwise. While it's far from a world-class
integration like the one Bitwarden offers, it's good enough for me for
the time being.

### No CLI

A CLI would have been a nice to have, but I rarely need to input
passwords on the command line these days anyways, since most tools now
use OAuth. Worst case, I can build one myself.

### No explicitly public API (let me explain)

I'm not going to say that there's no public API, because [there is](https://mozilla-services.readthedocs.io/en/latest/sync/).
But this document [is not enough by itself](scripting-firefox-sync-lockwise-complete-oauth.md#bonus-references)
to do anything useful with your Lockwise passwords.

It [took](scripting-firefox-sync-lockwise-existing-clients.md)
[me](scripting-firefox-sync-lockwise-figuring-the-protocol.md)
[days](scripting-firefox-sync-lockwise-understanding-browserid.md)
to figure out how to implement what was the legacy way
of reading passwords from Firefox Sync, and it took me
[even](scripting-firefox-sync-lockwise-hybrid-oauth.md)
[longer](scripting-firefox-sync-lockwise-complete-oauth.md)
to figure out the little documented but up-to-date way of doing so. I
wrote about it [in this series](scripting-firefox-sync-lockwise-existing-clients.md),
and I really wish it didn't need to be that long.

It seems to me that the main reason this API and documentation is public
is because Mozilla works in the open. They share all their code,
documentation, and even some (most?) of their communications. But they
don't necessarily *intend* them to be consumed by third-party developers
and end-users like me.

<div class="note">

**Positive note:** the fact that it was particularly hard to build
something with the "public but not really" Firefox Sync API made me dig
very deep in the code and protocols behind it, and I now have a better
understanding of the tool than I would have had if it featured a
comprehensive API client in the first place. Because I "reviewed" so
much of the code behind Lockwise, I'm now even more confident about
trusting it with my passwords.

</div>

## Conclusion

I find it pretty funny that the main reason I'm switching password
managers is to be able to use it from my phone, yet I chose Lockwise
which have a pretty limited mobile experience.

It just turns out that my use case on mobile overlaps exactly with the
part that the Lockwise app is good at (being a read-only password
manager).

Overall, the fact that Lockwise is baked in the browser gives it the
ability to provide a better experience than an extension would, and
while they do a solid job on desktop, they don't leverage that ability
to its full potential on mobile.

If you're a heavy mobile user, Lockwise is probably a no-go just because
of the lack of password generation feature (Bitwarden is probably a
better option for you at that point), but otherwise, it does an
excellent job at giving you access to existing passwords on your phone,
whether it's in the browser or native apps.

In the end, it doesn't really matter what password manager you're going
to use, as long as you actually use one!
