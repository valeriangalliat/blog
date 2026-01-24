---
tweet: https://x.com/valeriangalliat/status/1787213611267674227
---

# Send Cloudflare Workers logs to Google Cloud Logging using Logpush
May 5, 2024

Cloudflare Workers are great, until they become a key part of your
production system and you realize you don't have any logs. 😅

Something didn't work the way it should? Woops, sorry, can't do much
about that, I have no trace of what happened. 🤷

Not ideal.

<div class="note">

**Note:** sure there's the option to tail logs from the dashboard and
the CLI, but it turns out most of the logs I need don't get logged while
I'm watching. 👀

</div>

For a while, the alternative was to replace `console.log` statements by
`fetch` requests to something that will actually persist logs. Fine, but
still not ideal.

Thankfully they introduced [Logpush for Workers](https://blog.cloudflare.com/logpush-for-workers/)
back in 2022, which finally gave us a way to forward worker logs to a
number of [destinations](https://developers.cloudflare.com/logs/get-started/enable-destinations/),
including Amazon S3, Google Cloud Storage, Datadog, Elasticsearch,
BigQuery and more.

But none of those options was Google Cloud Logging. And I like to
centralize my logs in Google Cloud Logging. Bummer.

## Leveraging the HTTP destination

One of those options though is an arbitrary [HTTP destination](https://developers.cloudflare.com/logs/get-started/enable-destinations/http/).

With that, I should be able to integrate any log backend I want.

What if I made a Cloudflare Worker to handle the logs of my other
workers? That log drain worker probably shouldn't drain logs to itself
to avoid an infinite recursion, but I could fallback in one of the other
integrations just for this one.

## Configuring a Logpush handler

In order to use Cloudflare Logpush, [you need to be under the Cloudflare Enterprise plan](https://developers.cloudflare.com/logs/about/).
However there's an exception for the Cloudflare Workers logs! Then all
you need is the [Workers Paid](https://developers.cloudflare.com/workers/platform/pricing/)
plan.

You can configure a log handler from your dashboard, in **Analytics &
Logs > Logs > Add Logpush job**. Select **Workers trace events** as a
dataset, select the fields you care about (more on that later), and
configure your HTTP endpoint.

This UI looks like a recent addition! When I originally worked on this,
Logpush was only configurable [by using the Cloudflare HTTP API](https://developers.cloudflare.com/logs/get-started/enable-destinations/http/#manage-via-api).

For the record, and because it gives you more control over the Logpush
settings, here's how you would do this with the API.

First, you need an API token, which you can create from **My Profile >
API Tokens**.

While the API docs often reference the usage of API keys with
`X-Auth-Email` and `X-Auth-Key` headers, those API keys have complete
permissions over your account, and I would recommend against using them
if you have a better alternative.

The better alternative: API _tokens_, which lets you scope permissions.
In our case, we want to create a custom token with permissions of
`Zone.Logs.Edit`. That token can then be used in a `Authorization:
Bearer` header.

Here's how you would list existing Logpush jobs:

```sh
curl \
    -H "Authorization: Bearer $TOKEN" \
    'https://api.cloudflare.com/client/v4/accounts/my-account-id/logpush/jobs'
```

Where `my-account-id` is your account ID, that you can find for example
in the **Workers & Pages > Overview** page on the right.

To create a job:

```sh
curl \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    'https://api.cloudflare.com/client/v4/accounts/my-account-id/logpush/jobs' \
    --data '{
  "name": "test",
  "output_options": {
    "field_names": ["DispatchNamespace", "Entrypoint", "Event", "EventTimestampMs", "EventType", "Exceptions", "Logs", "Outcome", "ScriptName", "ScriptTags", "ScriptVersion"],
    "timestamp_format": "rfc3339"
  },
  "destination_conf": "https://my.worker.workers.dev",
  "dataset": "workers_trace_events",
  "enabled": true
}'
```

Where the API shines compared to the UI, is that you can configure a
number of [extra options](https://developers.cloudflare.com/api/operations/post-accounts-account_identifier-logpush-jobs#request-body)
like `max_upload_bytes`, `max_upload_interval_seconds` and
`max_upload_records`, to make sure Logpush makes requests within
acceptable limits for your endpoint.

In our case, the Logpush handler is also a Cloudflare worker so the max
body size will be between 100 MB and 500 MB [depending on your plan](https://developers.cloudflare.com/workers/platform/limits/#request-limits).
But also, Cloudflare workers have a [memory limit](https://developers.cloudflare.com/workers/platform/limits/)
of 128 MB so that's something to take into account as well. Oh and keep
in mind [this memory limit is per-isolate](https://community.cloudflare.com/t/workers-memory-limit/491329/2)
meaning that multiple requests could hit the same isolate. So adjust
accordingly, but I don't have a silver bullet for this one. 🙃

<div class="note">

**Note:** in my experience, setting `timestamp_format` to `rfc3339`
doesn't do anything? I'm still only getting `TimestampMs` fields in
milliseconds (which interestingly is neither a `unix` (seconds) nor
`unixnano` (nanoseconds) timestamp, which are the other two possible
options).

</div>

In order to update a job, you'll need the `id` that was returned by the
create request, or simply fetch it with the list request. It's gonna be
like the create request but you append the log ID in the end, e.g.
`logpush/jobs/12345`, it's a `PUT` request, and all fields are optional.

To delete a job, same but it's a `DELETE` request with no body.

## The Logpush HTTP destination protocol

I didn't find documentation about what the HTTP destination is supposed
to accept, so here's what I figured out:

* It sends a `POST` request to the configured URL.
* The body is gzipped.
* The uncompressed body is a newline-delimited JSON of "events", e.g.:

```json
{"DispatchNamespace":"","Entrypoint":"","Event":{"RayID":"87ed87f80cf22d84","Request":{"URL":"https://test.workers.dev/","Method":"GET"},"Response":{"Status":200}},"EventTimestampMs":1714878560011,"EventType":"fetch","Exceptions":[],"Logs":[{"Level":"log","Message":["bar","foo"],"TimestampMs":1714878560016}],"Outcome":"ok","ScriptName":"test","ScriptTags":[],"ScriptVersion":{"ID":"1e7519b3-08e2-441d-ae10-7c8c6d3b7e17","Message":"","Tag":""}}
{"DispatchNamespace":"","Entrypoint":"","Event":{"RayID":"87ed87fb49cb2d84","Request":{"URL":"https://test.workers.dev/","Method":"GET"},"Response":{"Status":200}},"EventTimestampMs":1714878560532,"EventType":"fetch","Exceptions":[],"Logs":[{"Level":"log","Message":["bar","foo"],"TimestampMs":1714878560532}],"Outcome":"ok","ScriptName":"test","ScriptTags":[],"ScriptVersion":{"ID":"1e7519b3-08e2-441d-ae10-7c8c6d3b7e17","Message":"","Tag":""}}
```

When you configure the HTTP destination, you get a chance to choose
which of those fields are included. You'll get a different set of fields
depending on the kind of dataset you're dealing with, but in the scope
of this article we're focusing on worker logs.

For reference, here's the list of supported [zone-scoped datasets](https://developers.cloudflare.com/logs/reference/log-fields/zone/)
and [account-scoped datasets](https://developers.cloudflare.com/logs/reference/log-fields/account/).
Zone-scoped datasets like DNS logs are tied to a specific "zone"
(a specific domain), while account-scoped datasets like worker logs are
global to your account (workers don't belong to a particular zone).

## Writing the worker

The worker will need to decompress the gzipped body, split it into lines
and send the individual logs to the Google Cloud Logging API.

Calling Google Cloud APIs from Cloudflare Workers is a bit of a
challenge because the Node.js SDK is not compatible with the workers
environment, so we need to reimplement the whole authentication process.
But it's a problem [we've already solved in the past](../../2022/02/how-to-call-google-cloud-apis-from-cloudflare-workers.md)
so it should be no big deal. 😎

First let's start with the base of the worker, including decompressing
the body:

```js
export default {
  async fetch (request) {
    if (request.method !== 'POST') {
      return new Response('', { status: 405 })
    }

    const ds = new DecompressionStream('gzip')
    const stream = request.body.pipeThrough(ds)
    const body = await new Response(stream).text()
    const logs = body.split('\n')

    for (const json of logs) {
      if (json.trim() === '') {
        continue
      }

      const log = JSON.parse(json)

      console.log(log)
    }

    return new Response()
  }
}
```

To do that, we use the native
[`DecompressionStream`](https://developer.mozilla.org/en-US/docs/Web/API/DecompressionStream),
that we can then [convert to text](https://stackoverflow.com/a/72718732/4324668)
with `await new Response(stream).text()`.

## Calling the Google Cloud Logging API

Now let's see how we can call the Google Cloud Logging API. Again, we
can't use the Google Cloud Node.js SDK, so we need to call the REST API
manually. Everything about authentication is explained in
[this post](../../2022/02/how-to-call-google-cloud-apis-from-cloudflare-workers.html)
so I won't cover that again. Read that article to understand how to deal
with Google Cloud API authentication from a Cloudflare worker!

When it comes to Google Cloud Logging specifically, you'll need an `aud`
of `https://logging.googleapis.com/` in your JWT. The rest of this post
will assume you generated a `token` variable thanks to the
aforementioned article.

In order to write logs, we need to call the [`entries:write`](https://cloud.google.com/logging/docs/reference/v2/rest/v2/entries/write)
endpoint.

```js
const res = await fetch(
  `https://logging.googleapis.com/v2/entries:write`,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({
      entries: [
        {
          logName: `projects/my-project-id/logs/my-log-id`,
          resource: {
            type: 'generic_node',
            labels: {
              // project_id: '...',
              // location: '...',
              // namespace: '...',
              // node_id: '...'
            }
          },
          // severity: 'DEFAULT',
          timestamp: '2024-05-05T17:38:47.512Z',
          jsonPayload: {
            foo: 'bar
          }
        }
      ]
    })
  }
)
```

Replace `my-project-id` by your project ID. `my-log-id` can be anything.

Here I chose to use a `generic_node` resource type, but there's
[quite a lot of other choices](https://cloud.google.com/logging/docs/api/v2/resource-list#resource-types)
so feel free to use what makes the most sense to you.

The resource type that you chose will have a number of associated labels
that you can feed. In this example I included the `generic_node` labels.
`project_id` doesn't really need to be set because it will be
automatically populated from the project ID in your `logName`. The other
ones are also optional. Put what makes the most sense for your data!

There's a number of other fields you can set on each [log entry](https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry)
in the `entries` array, but I kept it simple for this example.

You can for example tune the
[`severity`](https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogSeverity),
e.g. to distinguish `WARNING` and `ERROR` logs appropriately.

## Formatting Logpush logs to Google Cloud Logging entries

Let's look in a bit more details at a worker log received from Logpush:

```json
{
  "DispatchNamespace": "",
  "Entrypoint": "",
  "Event": {
    "RayID": "87ed87f80cf22d84",
    "Request": {
      "URL": "https://test.workers.dev/",
      "Method": "GET"
    },
    "Response": {
      "Status": 200
    }
  },
  "EventTimestampMs": 1714878560011,
  "EventType": "fetch",
  "Exceptions": [],
  "Logs": [
    {
      "Level": "log",
      "Message": [
        "bar",
        "foo"
      ],
      "TimestampMs": 1714878560016
    }
  ],
  "Outcome": "ok",
  "ScriptName": "test",
  "ScriptTags": [],
  "ScriptVersion": {
    "ID": "1e7519b3-08e2-441d-ae10-7c8c6d3b7e17",
    "Message": "",
    "Tag": ""
  }
}
```

And here's the associated [docs](https://developers.cloudflare.com/logs/reference/log-fields/account/workers_trace_events/).

As we can see, we get one entry per "event" which in this case, is a
whole HTTP request completing.

Then for this particular HTTP request, we've got an array of `Logs` that
the worker outputted during its runtime.

<div class="note">

**Note:** interestingly, the above log `["bar", "foo"]` was generated
by:

```js
console.log('foo', 'bar')
```

So it looks like the `Message` array is the reverse of the arguments
order that was passed to `console.log`.

Weird, but OK.

</div>

From there, it's up to you how you translate that to Google Cloud
Logging entries. You could:

1. Use the whole "event" as a single log entry and dig in the `Logs`
   property to see the actual logs. Then you could set the log severity
   based on the response status code, e.g. `ERROR` if the status is
   `>=400`.
1. Store the HTTP request "event" without logs in a separate entry, then
   map the `Logs` array to individual log entries. Then you could map
   the `Level` property to a log severity and have more granularity that
   way.

For this post, I'll take the lazy approach and just shove the whole
thing in the `jsonPayload`. 😄

Building off the [worker base from earlier](#writing-the-worker):

```js
const entries = []

for (const json of logs) {
  if (json.trim() === '') {
    continue
  }

  const log = JSON.parse(json)

  entries.push({
    logName: `projects/my-project-id/logs/my-log-id`,
    resource: {
      type: 'generic_node',
      labels: {
        namespace: log.ScriptName
      }
    },
    severity: log.Event.Response.Status >= 400 ? 'ERROR' : 'DEFAULT',
    timestamp: new Date(log.EventTimestampMs).toISOString(),
    jsonPayload: log
  })
}
```

Then as we saw before, we can push those entries to Google Cloud
Logging:

```js
const res = await fetch(
  `https://logging.googleapis.com/v2/entries:write`,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({
      entries
    })
  }
)
```

## Make your workers use Logpush!

The final step is to enable Logpush on your workers. By default, even if
you have Logpush destinations enabled, they won't be used unless
explicitly enabled at the worker level as well.

You can do that from the UI in your worker page, in **Logs > Event logs
Workers Logpush**. If you use the Wrangler CLI, make sure to also set
`logpush = true` in your `wrangler.toml`!

## Final thoughts

Getting your Cloudflare Workers logs onto Google Cloud Logging is not
easy, and using a Cloudflare worker for the integration layer makes it
even harder, but it's also kinda cool if you ask me. 😏

You should now have everything you need to implement that, from the
details of using the Cloudflare API to create Logpush jobs and tune it
in a way you can't do from the UI, implementing a HTTP Logpush
destination with gzip support, parsing the Logpush payload, all the way
to translating it for Google Cloud Logging and push it using the raw
HTTP API in an environment where the official SDK is not supported.

I hope you learnt a thing or two thanks to this post, and that your logs
are being happily ingested now! 🫶
