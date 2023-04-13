# Adobe Bridge mass update filetype associations
July 19, 2022

Bridge is a pretty powerful file explorer by Adobe, that
[now ships for free since the 2022 version](https://prodesigntools.com/free-adobe-bridge-cc.html).
Sweet.

But there's always one thing that bugs me with it: it keeps opening
photos in Photoshop, and Photoshop is sloooooow to start. When I
double-click on a picture, I most often just want to see it in Preview.

## The manual solution

The solution, is to go in "Preferences", "File Type
Associations" and associate pictures with Preview form there.

The problem is that there's *countless* different extensions for
pictures and we need to update them one by one! Bummer.

<figure class="center">
  <img alt="Bridge filetype associations" src="../../img/2022/07/bridge-preferences.png">
</figure>

It would be fine if it only had to happen once, but on any new Bridge
installation, or even after a major update, it resets and I have to
start over.

## The automated solution

Luckily there's a quick way to take everything that's currently
associated to Photoshop and replace it with Preview!

First, we need to manually associate at least one filetype in the
previous dialog. This will make sure that Bridge creates the file
`~/Library/Application Support/Adobe/Bridge 2022/Adobe Bridge Opener Preferences.xml`,
where it stores the filetype associations.

From there, we can open it and using a text editor, replace every
occurrence of `Photoshop` with `/System/Applications/Preview.app`.

If you want a one-liner to paste, this can even be done with `sed`:

```sh
sed -i '' 's,"Photoshop","/System/Applications/Preview.app",g' ~/Library/Application\ Support/Adobe/Bridge\ 2022/Adobe\ Bridge\ Opener\ Preferences.xml
```

After that, just restart Bridge and don't ever be scared of a file
randomly opening in Photoshop again!
