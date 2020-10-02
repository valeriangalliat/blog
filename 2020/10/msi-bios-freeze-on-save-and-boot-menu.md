MSI BIOS freeze on save and boot menu
=====================================
September 2, 2020

I've been having an issue on my rig for the past couple of months where
any time I go in the BIOS and go to the "Save & Exit", or any time I
open the boot menu, it just freezes and I need to reset. For reference,
my motherboard is a MSI H110M PRO-D.

This means I had no way of booting on something else than the default
boot priority, or to change any BIOS setting whatsoever.

I put it off for a while, but with the latest macOS update, I've had an
issue where it, well, wouldn't update, and I figured it might be
related.

When looking up that issue, a common suggestion is to reset CMOS.

I was kinda lazy to open the computer and I mostly didn't feel confident
about the procedure of shorting two pins that I wasn't 100% sure which
ones it was, and was worried I would cause more harm than good doing so.

Meet "AUTO CLR_CMOS".

## AUTO CLR_CMOS

Turns out "Boot" menu in the BIOS setup contains an option named "AUTO
CLR_CMOS". Enabling that gives access to another "Manual Mode" option,
that, when enabled, allows to reset CMOS by pressing the power button
for 6 seconds.

![BIOS](../../img/2020/10/bios.jpg)

This seems promising, but one of the reasons I want to clear CMOS is
because I can't save my BIOS settings as it freezes when I reach the
"Save & Exit" menu.

## Saving BIOS settings without going to the save menu

That day, I learnt that "in most BIOS" you can save the settings by
pressing F10. This worked for me, meaning that I didn't have to go into
the save menu (that just freezes) to save the BIOS settings.

Thanks to that trick I could enable the "AUTO CLR_CMOS" "Manual Mode".

With the computer off hold the power button. It will start, but as you
keep holding the button, after around 5 seconds, it shuts down again. It
seems that this triggered the reset of the CMOS (you can release at that
point).

Then wait 30 seconds or so (the power button had no effect for me during
that time, but it eventually works again).

On boot, you'll get prompted to enter setup or continue, after what your
BIOS settings are reset to default.

Resetting CMOS that way effectively fixed the freezing issue (both on
the "Save & Exit" menu as well as the boot menu) and I was able to
perform my update.
