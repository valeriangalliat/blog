# Prevent macOS to switch to bluetooth headphones microphone 🎧
May 5, 2024

Maybe like me, you have bluetooth headphones such as the Sony WH-1000XM4
that you like because they have great audio, but the built-in microphone
otherwise suck. But you don't care because you use your MacBook's
microphone.

Then, maybe also like me, you didn't even _know_ that it had a built-in
microphone in the first place, and even less that macOS was
automatically switching to that microphone when you connect your
headphones!

Luckily, I didn't sound like shit on calls for too long, because my
friends quickly told me "bro, ur mic sounds like shit". 💩

## Forcing the internal microphone

Now we know what's wrong, let's fix it. The idea is that when I connect
my bluetooth headphones, I want the audio output to go to them, but I
don't want to switch my default microphone.

We can achieve that with the **Audio MIDI Setup** app.

Create an **Aggregate Device** (from the `+` icon at the bottom-left
corner) that has only one input: your MacBook microphone. Then set this
aggregate device as "default for sound input" from the right click menu.

<figure class="center">
  <img alt="Audio MIDI Setup" srcset="../../img/2024/05/macos-microphone/audio-midi-setup.png 2x">
</figure>

Tada! Now connecting your headphones will leave the aggregate device
alone, meaning you'll keep using the good microphone that comes with
your laptop, without thinking about it. 👌
