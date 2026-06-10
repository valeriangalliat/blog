# AWS S3 flaky 403 on `HEAD` after upload
June 10, 2026

## TLDR

`HEAD` flaky? Use `GET` with `Range: bytes=0-0` instead.

## Context

Had a wild bug with S3 recently. Let's start with some context.

I'm currently building [Cloudmotion](https://cloudmotion.dev/),
a hosted Remotion Lambda.  [Remotion](https://www.remotion.dev/) is the
<abbr title="Greatest of all time">GOAT</abbr> when it comes to making
programmatic videos, and [Remotion Lambda](https://www.remotion.dev/lambda)
is the fastest way to render those videos in the cloud at scale.
**Cloudmotion is that but I deal with AWS so you don't have to.**

Part of the challenge is supporting _any_ Remotion version. There's
currently [over 1,200](https://www.npmjs.com/package/remotion?activeTab=versions)
published versions on npm, and new versions are released about every
other day.

In order to do that, the first time a new version is requested, I
trigger a AWS CodeBuild job that prepares the Lambda source, and uploads
a ZIP file to S3 that the function can be created from. In the `finally`
phase of the buildspec, I send a webhook to notify the app to continue
the provisioning with the newly built artifact.

The app then does a `HEAD` requests to check that the ZIP file exists
and then creates the Lambda from it. This is where things go sideways.

<div class="note">

**Note:** writing this post, I'm realizing I don't need that `HEAD` call
in the first place. I can just optimistically try to create the Lambda
assuming the ZIP file is there (normally, it should), and let the call
fail otherwise.

However I have other cases where I _do_ want that `HEAD` call to resume
provisioning from an existing artifact instead of starting a new build
all over. So it's not all lost, phew.

</div>

## Flaky `HEAD` response

I'm always calling the S3 API with the same, valid, credentials. So I'm
expecting 2 answers: 404 when the file doesn't exist, and 200 when it
does.

However here's some logs I've observed:

| Time         | Event       | result  |
|--------------|-------------|---------|
| 20:23:29     | `HEAD`      | 404     |
| 20:23:31     | `aws s3 cp` | success |
| **20:23:33** | **`HEAD`**  | **403** |
| 20:23:34     | `HEAD`      | 200     |

And another weird instance:

| Time         | Event       | result  |
|--------------|-------------|---------|
| **03:52:04** | **`HEAD`**  | **403** |
| 03:52:11     | `HEAD`      | 404     |
| 03:52:27     | `aws s3 cp` | success |
| 03:52:28     | `HEAD`      | 200     |

So while at first it felt like it could be due to doing the `HEAD` call
_really shortly_ after the upload succeeded, that second instance
actually shows us that even calls that expect a 404 can get a wild 403
instead, with the same credentials and permissions that got a 404 and
eventually a 200 seconds later.

## A note about eventual consistency

S3 has ["strong read-after-write consistency"](https://aws.amazon.com/s3/consistency/)
[since 2020](https://aws.amazon.com/blogs/aws/amazon-s3-update-strong-read-after-write-consistency/),
so it's been a while there's no more eventual consistency to deal with
when calling S3.

That being said I'm now realizing they say:

> Effective immediately, all S3 `GET`, `PUT`, and `LIST` operations
> [...] are now strongly consistent.

This doesn't include `HEAD`, so maybe `HEAD` is still eventually
consistent? But even with eventual consistency I'd expect a 404 after a
successful upload that eventually becomes a 200. In no way eventual
consistency should result in a 403 with valid credentials and
appropriate IAM permissions.

## Workaround

I never managed to understand the root cause of why those `HEAD` calls
randomly return a 403.

**Instead I switched to doing `GET` calls with `Range: bytes=0-0`.**
Returns a 404 consistently when the file doens't exist, and a 206
(partial content) when it does.

Bonus is that the `GET` method allows the S3 API to return proper XML
error responses, whereas `HEAD` by design doesn't have a HTTP body and
thus can't communicate any useful error information (especially in the
case of those 403s).
