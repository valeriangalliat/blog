Windows dual boot with VeraCrypt full disk encryption
=====================================================
November 2, 2020

## TLDR

1. To make a bootable USB with recent Windows ISO that contain an
   `install.wim` of more than 4 GB, it's easier to use [Rufus](https://rufus.ie/)
   from an existing Windows machine and let it do the job.
1. If you're going to use VeraCrypt, you *need* the EFI "System"
   partition to be on the same drive as your "Primary" Windows
   partition.
1. If you're installing Windows on a drive while you already have an EFI
   partition on another drive, the Windows installer *will not* create a
   new "System" partition on the same drive that it will be installed
   to, it will just add itself to the existing EFI partition. To have
   Windows boot from the same drive as it's installed to, you need to
   manually create a 100 MB partition on the same drive you will install
   Windows on, and later on, format it as FAT32 and move whatever the
   installer added to your existing EFI partition to that new one.

If you want to feel the pain, read on.

## The whole story

I have a laptop with a 500 GB SSD and a 1 TB HDD. It's currently running
Arch Linux which takes all the SSD, and the HDD is empty.

I wanted to add a Windows dual boot on the HDD, and have it encrypted
with VeraCrypt, TrueCrypt's successor, which seems the most standard
full disk encryption for Windows when not having one of the businesses
versions of Windows.

This sounded like a trivial task, I've installed many, many dual (or
more) boots whether it's Windows, Linux, BSD, macOS... on many different
computers and laptops for the past 10 years, so that should be a piece
of cake.

It ended up taking me a lot longer than I expected, and I'll document in
this blog post the issues I encountered, especially since the symptoms,
and, as usual with Windows, the errors messages, were really obscure and
misleading.

## Why bother encrypting?

Most of the issues I ran into were because I wanted to have full disk
encryption on Windows. Why bother?

It's the first time I'll have a laptop running Windows, and while I
never bothered encrypting my desktop Windows because the probability of
it being physically compromised is low and it only have my Steam account
and games anyways, it's another story for a laptop that I plan to carry
when travelling around the world.

At that point full disk encryption is a hard requirement for me; if my
laptop gets stolen, I'm just gonna take the *hardware* loss but I won't
have to worry about all my accounts, saved passwords and other secrets
being exposed[^1].

In the first place I assumed that like on macOS I would just have the
option to encrypt the partition at install time but turns out there's no
such option, and later on, you need to pay extra for the native Windows
encryption features, so that's why I went with VeraCrypt instead.

## Making a Windows bootable USB

The first challenge was to make a working Windows bootable USB. This
have been an issue for the past couple of years when making a Windows
bootable USB without using a tool like Rufus (usually when you're making
the key from another OS), but until now I've always managed to
circumvent it.

The easiest way of making a Windows bootable USB for EFI is normally to
format the key as FAT32, and just copy over the contents of the ISO to
it.

The issue is that recent (like, past year or two) Windows ISO comes with
a file, `install.wim`, that is more than 4 GB in size.

Why is that a problem in 2020? Turns out that at least on all the
machines I own at the moment, the BIOS can only boot from FAT32
partitions. And FAT32 doesn't allow for more than 4 GB files.

[Last time I needed to do that](../../2019/03/macos-high-sierra-msi-h110m-pro-d-skylake-nvidia-pascal.html#bonus-windows-dual-boot),
Windows offered an older ISO that didn't have that issue so I just used
that. This is not anymore an option.

### We couldn't create a new partition or locate an existing one (round 1)

My first attempt was to make a bootable USB drive with two partitions. I
found somewhere (can't find the link anymore) an article that documented
how you can make a FAT32 partition with everything but the `sources`
directory and then put everything again on a NTFS partition and that was
able to fix the issue.

While this did the trick to be able to *boot* the installer and go all
the way to partitioning the disk, for me this resulted in the following
error when actually running the install:

> We couldn't create a new partition or locate an existing one.

Looking online for this error message, it looks like there can be a
*fuckton* of totally unrelated issues that will give you that message,
so it's basically useless at that point.

In my case, my guess is that this is a way to tell me that the installer
can't find the `install.wim` or other sources it needs to continue with
the installation, essentially it didn't understand the second NTFS
partition thingy.

### Second attempt, Rufus

[Rufus](https://rufus.ie/) is a neat, Windows only piece of software to
make Windows bootable USB drives. Since I have a Windows on my desktop
computer, I just booted it instead to use Rufus to make the drive.

Rufus does something pretty similar to my first attempt, but does it in
a way that actually works, so that allowed me to complete the install!

## Encrypting the partition

Once Windows installed, I installed VeraCrypt and started the system
partition encryption process.

This does a "pretest" that just tries the VeraCrypt bootloader without
actually encrypting anything.

### Authorization failed, wrong password, PIM or hash

When I launched the VeraCrypt system partition encryption, it gave me a
message telling me that my system partition wasn't on the same drive
that the partition Windows was booting from, which is unsupported. But I
misread that and I continued anyways.

During the pretest, I would type my password in the VeraCrypt
bootloader, and even though I was 100% sure my password was right, it
kept telling me "authorization failed, wrong password, PIM or hash".

This happens when Windows isn't installed on the same drive that it
booted from, which turned out was the case for me, even though I
assumed it wasn't in the first place.

That's then that I realised that the Windows installer didn't create an
EFI partition on the drive I was installing it to, and it reused the
existing EFI partition on my SSD, the one that was normally booting just
my Arch Linux installation. While this behavior does makes some sense,
it's not what I wanted, and I didn't have the option to create that
second EFI partition from the installer, and even if I created it
manually, I couldn't get the installer to use it instead of the first
EFI partition that it identifies.

### What I could have done, but I didn't do (round 1)

An EFI partition is just a FAT32 partition anywhere on your drive really
that contains an `EFI` directory with a bunch of EFI shit inside. And it
just works like magic. Fucking awesome stuff.

So what I could have done, and in retrospective, should have done, is
just shrink the Windows partition by 100 MB, create at FAT32 partition
at the end of the disk, move whatever stuff the installer put in my EFI
partition on the SSD to that new partition, and boot from that. Easy.

But I'm a fucking maniac and I didn't like the idea of having my EFI
partition at the end of the disk, I wanted it to be neatly the first
thing on the disk. And you can't easily move partitions around on disk
like this. While I think it would be technically possible, it's not a
trivial thing and I gauged that it would probably be faster to just
reinstall Windows, but this time keeping extra room for the EFI
partition.

Will that make any difference in my life? No. Will I spend an extra 2+
hours to do it? Yes.

### Back to square one

I go back to the partitioning step of the Windows installer, and I
remove all the partitions form the Windows drive, and just hit the "New"
button which creates all the partition that Windows needs.

But again, this only creates the Microsoft "MSR (Reserved)" 16 MB
partition on top of the Windows "Primary" partition, but doesn't create
an extra "System" one, just like the first time.

### What I could have done, but I didn't do (round 2)

At that point what I could have done, was to manually create a regular
100 MB non-EFI partition first, then let Windows use the rest, and at
the end, format that 100 MB space as FAT32 and  manually move the EFI
stuff from the SSD EFI partition to the one I reserved earlier.

But I kinda wanted to find a way to make the Windows installer create
that partition itself, and have it install to it directly without me
having to move anything at the end (spoiler: I failed).

### Thinking out of the box

That's when things get interesting. The next thing I tried, which in
retrospective was still a smart idea even though it didn't work, was to
find a way to deactivate or like, virtually "disconnect" the SSD
altogether so that the installer doesn't even consider using the EFI
partition that's on it.

Turns out in Microsoft language this is called "offlining" the disk.

To offline a disk from the installer, press <kbd>Shift</kbd> +
<kbd>F10</kbd> to open a terminal. Launch `diskpart`.

Use `list disk` to identify the disk you want to offline, then type
`select disk 0` (replace with the number of the disk you want to
offline), and then `offline disk`.

Now if I remove all partitions of the hard drive and click "New" again,
it'll create not two, but three new partitions on the drive, including
the "System" one. Win!

Well, not really.

### We couldn't create a new partition or locate an existing one (round 2)

If you click "Next" at that point, which normally launches the
installation process, you get this error instead:

> We couldn't create a new partition or locate an existing one.

Sounds familiar.

So I'm gonna skip the part where I think that I fucked up something on
my USB key and that even though I made it with Rufus the `install.wim`
or something got fucked up in a way or another (it could have been
somewhat remotely possible since I shrank the NTFS partition on the USB
to make a new partition for the VeraCrypt USB backup thing which really
wanted it's own partition).

Now we're a couple hours later and I start to consider that that USB and
`install.wim` is actually fine, and even though I'm getting the same
error message than earlier today, it *must* be something else.

Maybe the Windows installer doesn't like that I have two EFI partitions
on different drives, even though one of them is marked as offline.

I online the disk again, now the installer happily displays me the two
"System" partitions, each one on their own drive. I click "Next", but I
get the same error message.

So at that point, I delete the second "System" partition that was just
created, and start the installation process.

This works, but I still can't use VeraCrypt as Windows is still booting
form the EFI partition on the SSD.

### Two things I could have done instead

1. Open the laptop and physically unplug the SSD.
2. Backup the contents of my Arch Linux boot partition, then remove it
   altogether. This way Windows wouldn't have been confused by another
   EFI partition present on another disk. And after installing Windows,
   make the Arch Linux boot partition back with the backup of its
   contents.

Both are pretty annoying to do but would have worked.

### Making Windows boot from the drive it's installed on

Finally, all that's left to do is to make a new partition in the empty
100 MB space that I left at the beginning of the drive, format it as
FAT32, and move everything that Windows added to the EFI partition of my
SSD back to that new "System" partition.

This works and I could finally get the VeraCrypt pretest to pass and
thus encrypt the whole partition.

## Bonus, install Windows without a Microsoft account

When Windows is done installing, which takes ages so you're likely
focusing on something else, it first surprises you with a loud Cortana
voice that tells you a bunch if shit you don't need to hear.

Once you acknowledge the fact that there's not actually a creepy woman
that just started talking somewhere in your apartment, and since you're
already interrupted from whatever else you were doing, you get up and go
mute it, and then you let it do a bunch more shit that don't need you to
be around for the next 10 minutes or so.

Eventually it actually needs input from you and you can deny the 42
different ways that Microsoft wants to track you, or for some of them,
only accept a subset of the tracking, since you can't deny it
completely.

Finally, you get prompted to log in to your Microsoft account, or create
one otherwise.

I could swear there used to be some small link somewhere on this screen
that allowed to create an offline account. It's definitely not there
anymore.

One thing that you can do is not connect to Wi-Fi in the first place,
but obviously when you realize that, it's already too late, and the
installer doesn't allow you to disconnect Wi-Fi.

At that point you can turn of your Wi-Fi access point, or blacklist the
IP of your Windows system from your Wi-Fi router, or if you're
connecting with a RJ45 cable instead, well, just unplug it, and then
type some garbage in the login form.

Another thing you can do is open a command prompt with the good old
<kbd>Shift</kbd> + <kbd>F10</kbd> and type `netsh interface show
interface` to show the available network interfaces. Identify the one(s)
you're connected to, likely something as easy as "Wi-Fi", but you could
have some numbers around there too, and then type `netsh interface set
interface "Wi-Fi" disable`.

Now you can put garbage in the login form as well and when it'll fail,
you'll get the option to create an offline account.

Then you can replace `disable` by `enable` in the previous command to
turn the network interface back on.

## Conclusion

After all this shit I'm kind of tired to write a conclusion, but in
summary, at the beginning, I thought oh, I've made dual boots all my
life, it should be pretty trivial I'm just gonna enable some kind of
full disk encryption on top of it this time.

That "just" ended up being a bit more work than I expected it to, and
you can draw your own conclusions form that, if any.

[^1]: At least assuming that the laptop is off when it gets stolen, or
that the attacker doesn't have enough knowledge and tooling to be able
to unlock an already booted Windows machine without password, or extract
the decryption key from the memory of an already running Windows machine
using VeraCrypt. Might not resist the NSA but mostly should be fine with
someone who snatches my laptop from a random coffee terrasse and runs
away.
