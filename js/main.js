/* eslint-env browser */

/**
 * Adapted from <https://stackoverflow.com/questions/45866873/cropping-an-html-canvas-to-the-width-height-of-its-visible-pixels-content>.
 */
function trimCanvas (ctx) {
  let { width, height } = ctx.canvas

  if (!width && !height) {
    return
  }

  const imageData = ctx.getImageData(0, 0, width, height)

  // Since `imageData.data` is a `Uint8ClampedArray` with 4 bytes per pixel,
  // interpreting its raw source buffer as a `Uint32Array` will "concat" those
  // 4 bytes so each array element is a single pixel and if it's non-zero it
  // means it's not transparent.
  const data = new Uint32Array(imageData.data.buffer)

  let top, left, right, bottom
  let i = 0
  let j = width * height - 1
  let found = false

  for (let y = 0; y < height && !found; y += 1) {
    for (let x = 0; x < width; x += 1) {
      if (data[i++] && top === undefined) {
        top = y

        if (bottom !== undefined) {
          found = true
          break
        }
      }

      if (data[j--] && bottom === undefined) {
        bottom = height - y - 1

        if (top !== undefined) {
          found = true
          break
        }
      }
    }

    // Image is completely blank.
    if (y > height - y && top === undefined && bottom === undefined) {
      return
    }
  }

  found = false

  for (let x = 0; x < width && !found; x += 1) {
    i = top * width + x
    j = top * width + (width - x - 1)

    for (let y = top; y <= bottom; y += 1) {
      if (data[i] && left === undefined) {
        left = x

        if (right !== undefined) {
          found = true
          break
        }
      }

      if (data[j] && right === undefined) {
        right = width - x - 1

        if (left !== undefined) {
          found = true
          break
        }
      }

      i += width
      j += width
    }
  }

  width = right - left + 1
  height = bottom - top + 1

  if (width > height) {
    ctx.canvas.width = width
    ctx.canvas.height = width
    top -= (width - height) / 2
  } else if (height > width) {
    ctx.canvas.width = height
    ctx.canvas.height = height
    left -= (height - width) / 2
  } else {
    ctx.canvas.width = width
    ctx.canvas.height = height
  }

  ctx.putImageData(imageData, -left, -top)
}

/**
 * Why not use a SVG instead using the emoji in a text object?
 *
 * Like documented here <https://css-tricks.com/emojis-as-favicons/>.
 *
 * Well, this isn't consistent on all platforms. On a given system you can
 * tweak the font size and the X/Y position to some magic numbers for it not
 * overflow or be too small or not centered, but your magic numbers won't work
 * for another system. And if you optimize for that second system, well it's
 * not gonna work anymore on the first one.
 *
 * So the most reliable way I found so far is to render the emoji to a bigger
 * canvas than it needs, and then trim it to the edges keeping a square ratio.
 */
function emojiFavicon (emoji) {
  const canvas = document.createElement('canvas')

  // Use a bigger canvas than the font size as on most systems a 64px emoji
  // rendered that way will overflow a 64px by 64px canvas.
  canvas.height = 128
  canvas.width = 128

  const ctx = canvas.getContext('2d')
  ctx.font = '64px sans-serif'
  ctx.fillText(emoji, 0, 64)

  // Fit the canvas to non-transparent edge pixels keeping a square ratio.
  trimCanvas(ctx)

  const favicon = document.createElement('link')
  favicon.rel = 'icon'
  favicon.href = canvas.toDataURL()

  document.head.appendChild(favicon)
}

emojiFavicon('🍺')
