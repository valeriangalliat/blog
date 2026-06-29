# Generate subtitles for audio/video on Mac
June 29, 2026

I started posting daily [on X](https://x.com/valeriangalliat),
including, sometimes, videos. And it turns out X isn't able to
automatically generate captions for the video like other platforms do.
They do give the option to upload a SRT file though.

Since I want to keep things minimal I'm gonna use that option, as I
don't want to get down the rabbit hole of burning stylized captions in
the video itself like you see all over short form content. That's for
another day.

Most of the options to create subtitles from audio require to call a
paid transcription API, like OpenAI's `gpt-4o-transcribe` or ElevenLabs.
But I'm not paying to caption my random yapping on X, thank you.

## The best local option

As far as I can tell the best open-source model for this that can be run
locally is [OpenAI Whisper](https://github.com/openai/whisper),
originally released in 2022, with a v3 update in 2023.

While not state of the art, we can run this locally for free and it
performed perfectly in my case of speaking English with a heavy French
accent (which often defeats transcription models including the ones of
Slack and YouTube).

The following is for a Silicon Mac using Apple MLX for performance:

```sh
brew install pipx
pipx install mlx-whisper
```

Then:

```sh
mlx_whisper your-video.mp4 --model mlx-community/whisper-large-v3-mlx -f srt
```

This will produce a SRT file next to the input video.

## Turbo version

It's also possible to use the Whisper v3 Turbo variant that OpenAI released in
2024, which is ["way faster at the expense of a minor quality degradation"](https://huggingface.co/openai/whisper-large-v3-turbo).

```sh
mlx_whisper your-video.mp4 --model mlx-community/whisper-large-v3-turbo -f srt
```

However I had some slight glitch with it that didn't happen in the
normal version. Also it seems to make longer lines in captions, and I
like the way the non-Turbo version splits lines better.

## Non-MLX

For the non-MLX version if you need. This should run on any Mac.

```sh
brew install openai-whisper
whisper your-video.mpk --model large --output_format srt
whisper your-video.mpk --model turbo --output_format srt
```

## Even faster?

For even faster transcription, I heard about
[lightning-whisper-mlx](https://github.com/mustafaaljadery/lightning-whisper-mlx),
but didn't get to try it as it doesn't come with a CLI. Need to call it
from Python instead, and I'm lazy to do that given that `mlx_whisper`
is way fast enough for my short videos anyway.

Let me know how it goes if you try it. ✌️
