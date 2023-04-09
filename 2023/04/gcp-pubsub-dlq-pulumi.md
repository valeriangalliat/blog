# Configuring a GCP Pub/Sub dead letter queue with Pulumi
April 8, 2023

I've been playing a bit with [Pulumi](https://www.pulumi.com/) lately,
and it quickly became one of my favorite infrastructure as code tools.
It feels like the power of [AWS CDK](https://aws.amazon.com/cdk/) which
lets you code your infrastructure in a full-fledged scripting language,
but without being limited to AWS!

I like coding my infrastructure in TypeScript because the typing,
autocomplete and IDE integrations makes it particularly nice to discover
the SDK on the fly as you're creating your infrastructure, so that's
what I'll use in the examples.

Today, we're gonna see how to programmatically create a Pub/Sub topic
and subscription on GCP, with a matching dead letter queue. Finally,
we'll add a monitoring alert policy to warn us when our
<abbr title="Dead letter queue">DLQ</abbr> is not empty.

## Getting started

If you already have Pulumi installed, and an existing project, you can
skip this. In order to install Pulumi on macOS, run:

```sh
brew install pulumi
```

Create an account on Pulumi if you don't have one already, then create a
new directory for your project, and inside it, run:

```sh
pulumi new gcp-typescript
```

Follow the instructions to initialize your project and connect it to
your GCP account.

Finally, you can remove the default code from `index.ts` that creates a
test bucket.

## Creating a topic and a subscription

```ts
import * as gcp from '@pulumi/gcp'

const topic = new gcp.pubsub.Topic('hello-world-topic', { name: 'hello-world' })

const subscription = new gcp.pubsub.Subscription('hello-world-subscription', {
  name: 'hello-world',
  topic: topic.id
})
```

This will create a topic and a basic pull subscription, that you can...
subscribe to using the Google Cloud SDK in your favorite language.

## Adding the dead letter queue

On GCP, a dead letter queue consists in configuring an existing
subscription to send messages that failed a number of times to another
topic. Having a subscription on that dead letter topic, even if it has
no consumer, lets us store those messages for a period of time, so we
can eventually do something with them.

Here's our DLQ:

```ts
const dlqTopic = new gcp.pubsub.Topic('hello-world-dl-topic', { name: 'helo-world-dl' })

new gcp.pubsub.Subscription('hello-world-dl-subscription', {
  name: 'hello-world-dl',
  topic: dlqTopic.id
})
```

Then we can add the dead letter policy to our existing subscription:

```diff:ts
 const subscription = new gcp.pubsub.Subscription('hello-world-subscription', {
   name: 'hello-world',
   topic: topic.name,
+  deadLetterPolicy: {
+    deadLetterTopic: dlqTopic.id,
+    maxDeliveryAttempts: 5
+  }
 })
```

`maxDepliveryAttempts` is optional and defaults to 5. When a messaged
failed to be delivered that many times, it'll be sent to the DLQ.

You may also like to tweak your subscription's retry policy at that
point. By default, it retries a failed message immediately, but you can
configure an exponential backoff instead:

```diff:ts
 const subscription = new gcp.pubsub.Subscription('hello-world-subscription', {
   name: 'hello-world',
   topic: topic.id,
+  retryPolicy: {
+    minimumBackoff: '10s',
+    maximumBackoff: '600s'
+  },
   deadLetterPolicy: {
     deadLetterTopic: dlqTopic.id,
     maxDeliveryAttempts: 5
   }
 })
```

While you don't have precise control over the exponential backoff
behavior, you can tweak the minimum and maximum duration that Pub/Sub
will wait before retrying a message. Anything in between is out of your
control.

## Handling permissions

But we're not done yet! If you go to your subscription page, you'll
notice the following issues warnings:

<figure class="center">
  <img alt="Permission issues with dead letter queue" srcset="../../img/2023/04/pubsub-dlq-warning.png 2x">
</figure>

> ❗️ **Assign Publisher role**
>
> The Cloud Pub/Sub service account for this project needs the publisher
> role to publish dead-lettered messages to the dead letter topic.
>
> ❗️ **Assign Subscriber role**
>
>The Cloud Pub/Sub service account for this project needs the subscriber
> role to forward messages from this subscription to the dead letter topic.

You can identify the Pub/Sub service account in your IAM principals
list, by ticking "include Google-provided role grants". It's always
under the form `service-{projectId}@gcp-sa-pubsub.iam.gserviceaccount.com`.

We can fix that in our Pulumi code by adding the following:

```ts
import * as pulumi from '@pulumi/pulumi'

const project = gcp.organizations.getProjectOutput()

const pubSubServiceAccountPublisherPolicy =
  gcp.organizations.getIAMPolicyOutput({
    bindings: [
      {
        role: 'roles/pubsub.publisher',
        members: [
          pulumi.interpolate`serviceAccount:service-${project.number}@gcp-sa-pubsub.iam.gserviceaccount.com`
        ]
      }
    ]
  })

const pubSubServiceAccountSubscriberPolicy =
  gcp.organizations.getIAMPolicyOutput({
    bindings: [
      {
        role: 'roles/pubsub.subscriber',
        members: [
          pulumi.interpolate`serviceAccount:service-${project.number}@gcp-sa-pubsub.iam.gserviceaccount.com`
        ]
      }
    ]
  })

new gcp.pubsub.TopicIAMPolicy('hello-world-dl-topic-policy', {
  topic: dlqTopic.name,
  policyData: pubSubServiceAccountPublisherPolicy.policyData
})

new gcp.pubsub.SubscriptionIAMPolicy('hello-world-subscription-policy', {
  subscription: subscription.name,
  policyData: pubSubServiceAccountSubscriberPolicy.policyData
})
```

Now our Pub/Sub DLQ page should be all green!

## Getting alerted for new messages in the DLQ

The first thing you usually do when you create a DLQ is add a mechanism
to _know_ when messages hit the DLQ, so that you can act on them.

When it comes to alert policies, I typically create them in the GCP
console, then I use the "download as JSON" button in the policy details.
I can use this verbatim inside Pulumi's `gcp.monitoring.AlertPolicy`
constructor!

Here's what I've got when I made an alert policy to get notified when
any of my subscriptions whose name ends with `-dl` has undelivered
messages.

```ts
const notificationChannels = [
  'projects/{projectId}/notificationChannels/{channelId}'
]

new gcp.monitoring.AlertPolicy('alert-policy-pubsub-dl', {
  alertStrategy: {
    autoClose: '604800s'
  },
  combiner: 'OR',
  conditions: [
    {
      conditionThreshold: {
        aggregations: [
          {
            alignmentPeriod: '300s',
            perSeriesAligner: 'ALIGN_MEAN'
          }
        ],
        comparison: 'COMPARISON_GT',
        duration: '0s',
        filter: `
              resource.type = "pubsub_subscription"
          AND metric.type = "pubsub.googleapis.com/subscription/num_undelivered_messages"
          AND resource.labels.subscription_id = ends_with("-dl")
        `,
        thresholdValue: 0,
        trigger: {
          count: 1
        }
      },
      displayName: 'Cloud Pub/Sub Subscription - Unacked messages'
    }
  ],
  notificationChannels,
  displayName: 'Pub/Sub messages in dead letter'
})
```

Just put the ID of your notification channel in the array on top. To
find it, you can use the following command that will list all your
notification channels including their full ID:

```sh
gcloud alpha monitoring channels list
```
