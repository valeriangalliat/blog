# Changing default mail client on macOS without signing in to the Mail app
April 13, 2023

The things we have to do sometimes... 🙈

Maybe you use another mail client than the Mail app on macOS, and you
want to make it the default, so that when you click `mailto:` links, it
actually opens the app you want.

Apple documents how to do that in [change the default email app](https://support.apple.com/en-ca/HT201607):

> 1. Open the Mail app.
> 1. From the menu bar, choose **Mail > Settings**.
> 1. Click **General**.
> 1. Choose an email app from the **Default email reader** menu.

That's great, except it doesn't work. If you never used the Mail app,
which you probably didn't if you use another mail client, you can't
access the settings! You're greeted with this screen:

<figure class="center">
  <img alt="A dialog prompting you to set up a mail account" srcset="../../img/2023/04/mail/01-blocking-dialog.png 2x">
</figure>

And the settings are greyed out!

<figure class="center">
  <img alt="Greyed out settings menu" srcset="../../img/2023/04/mail/02-disabled-settings.png 2x">
</figure>

What to do then? There's [a number of solutions](https://apple.stackexchange.com/q/261881/452681):

* Connect your mail account to the Mail app to go through this dialog
  and finally access the settings.
* Use a number of different third-party apps that can change default
  associations.
* Write a script to mess with the `LaunchServices` API.

But [my](https://apple.stackexchange.com/a/422772/452681)
[favorite](https://osxdaily.com/2014/05/06/change-default-mail-app-mac/#comment-745047),
that doesn't require any third-party app, consists in selecting **Other
Mail Account**, putting garbage in the fields, and let it fail a few
times until it works!

<figure class="center">
  <img alt="Mail account settings" srcset="../../img/2023/04/mail/03-add-account.png 2x">
</figure>

This will obviously fail, and prompt you for more information:

<figure class="center">
  <img alt="Advanced account settings" srcset="../../img/2023/04/mail/04-add-account-error.png 2x">
</figure>

Just keep hitting the **Sign In** button until it gives up and lets you
through! You now have access to the settings menu.

<figure class="center">
  <img alt="Active settings menu" srcset="../../img/2023/04/mail/05-settings-menu.png 2x">
</figure>

From there, you can set your **Default email reader** to your favorite
app.

<figure class="center">
  <img alt="Default email reader settings" srcset="../../img/2023/04/mail/06-settings.png 2x">
</figure>

## Using Gmail inside Firefox as default email reader on macOS

In my case, I selected the Firefox app in the previous step, because I
want to use Gmail inside Firefox as my default email reader.

With that, the next time you open a `mailto:` link from anywhere on your
system, it's going to open Firefox, and Firefox will then need to know
you want to use Gmail for this. Normally it'll prompt you the first
time, but you can also configure it in the **Applications** settings:

<figure class="center">
  <img alt="Firefox settings" srcset="../../img/2023/04/mail/07-firefox-settings.png 2x">
</figure>

I hope this helps!
