---
tweet: https://x.com/valeriangalliat/status/1457849255855542279
---

# ImageMagick crop with percentage like CSS `background-position`
November 8, 2021

Another one of those posts that are probably only useful to me, but who
knows!

I've been wanting to crop images with ImageMagick in a way that mimics
what the CSS `background-position` property does.

## How does `background-position` behave?

Let's say I have a picture that I'm making shorter, e.g. a 1:1 picture
that I want to make 16:9, and I want to make sure to keep it centered
both horizontally and vertically. I would use the following:

```css
.element {
  background-position: 50% 50%;
}
```

In this particular case, we can easily mimic that with ImageMagick.
Let's assume `input.jpg` is currently a 1080x1080 square picture, and we
want to scale it down to a 640x360 16:9 landscape:

```sh
convert input.jpg -resize 640x -gravity center -crop 640x360+0+0 output.jpg
```

But `-gravity` only allows us to align top (`north`), center or bottom
(`south`). What if we wanted a percentage in between?

In the case of `background-position`, 0% would align the picture at the
top, and 100% at the bottom. Anything in between would allow to navigate
in that range.

## Applying it to ImageMagick

Let's pretend we can't do `-gravity south` to align the crop at the bottom,
and convert our 100% offset to a pixels offset. It would be equal to the
original picture height minus the target crop height, or in the case of
our example, `640 - 360`, which is 280 pixels.

```sh
convert input.jpg -resize 640x -crop 640x360+0+280 output.jpg
```

Similarly, our 75% becomes `75 / 100 * (640 - 360)`, which is 210.

But it gets a bit annoying to calculate that manually every time.
Instead, let me introduce the `magick` command!

## The `magick` command

`magick` behaves very similarly to `convert`, but supports some extra
features like the ability to embed calculations directly in the cropping
options!

```sh
magick input.jpg -resize 640x -crop '640x360+0+%[fx:75/100*(h-360)]' output.jpg
```

Here, the only variable we have to manually write down is the cropped
height, which we already need to know to perform the crop in the first
place.

With that, it gets easy to adjust the percentage in a way that's
consistent with what `background-position` would otherwise do, without
having to do the math by hand.

It was already possible to do this by combining `identify` and a command
line calculator like `bc`, but having the option to do that so easily in
the `-crop` option is definitely nicer!
