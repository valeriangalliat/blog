# Syncthing: sync phone root directory (all internal storage)
April 2, 2023

If you use Syncthing on your phone, it may not let you select the
phone's root directory as a shared folder source! At least that's the
case on my phone running Android 13.

<figure class="center">
  <img alt="Syncthing web GUI showing root directory path as text" srcset="../../img/2023/04/syncthing-forbidden.png 3x">
</figure>

As you can see, "use this folder" is greyed out and there's a warning
the folder can't be used for privacy reasons.

But I own that phone and I don't like being told what to do. In our
case, I want to be able to sync **all** of my phone's storage to my
computer, as a backup system.

So how to circumvent that?

Turns out we can do that through Syncthing's lesser known "web GUI"!

You can find it in the left menu (where you also exit Syncthing from).
It will open the web version of Syncthing. From there, instead of
selecting the directory to sync from your phone's native folder picker
(which may prevent you to use the root directory), you can just _input a
path_ as plain text.

<figure class="center">
  <img alt="Syncthing web GUI showing root directory path as text" srcset="../../img/2023/04/syncthing-web-gui.png 3x">
</figure>

Enter `/storage/emuilated/0` (or simply `~`), and there you go, you have
a Syncthing folder that syncs all of your phone's internal storage! 🙏
