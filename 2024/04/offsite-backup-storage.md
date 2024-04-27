# Encrypted offsite backup system: storage 💾
Comparing "cloud" storage solutions  
April 26, 2024

<div class="note">

1. Encrypted offsite backup system: storage 💾
1. [Encrypted offsite backup system: syncing 📲](offsite-backup-sync.md)

</div>

**Threat model:** my house burns. Or someone breaks in and takes my
computers and hard drives. Everything's encrypted so I'm not so worried
about them gaining access to my data but I'm concerned about losing my
data.  
**Solution:** offsite backup system.

**But then... threat model:** breach in the company / data center that hosts
my offsite backups, from a third-party attack or from maleovlent
employees.  
**Solution:** _end-to-end encrypted_ offsite backup system.

## Requirements

I have over 4 TB of data and I want a bit of buffer, so I'm only gonna
consider solutions for 5 TB of storage.

## Comparison

Let's start with everything I considered for offsite storage. If you
know better options, let me know!

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Plan</th>
      <th>Storage</th>
      <th>Monthly price (billed annually)</th>
      <th>Monthly price</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="https://www.sync.com/pricing/">Sync</a></td>
      <td>Teams+ Unlimited</td>
      <td>6 TB</td>
      <td>20 CAD</td>
      <td>24 CAD</td>
    </tr>
    <tr>
      <td><a href="https://web.archive.org/web/20221101213929/https://www.dropbox.com/plans"><s>Dropbox</s></a></td>
      <td><s>Standard</s></td>
      <td><s>5 TB</s></td>
      <td><s>15 USD</s></td>
      <td><s>18 USD</s></td>
    </tr>
    <tr>
      <td colspan="5">
        <em>Discontinued.</em>
      </td>
    </tr>
    <tr>
      <td><a href="https://www.dropbox.com/plans">Dropbox</a></td>
      <td>Business</td>
      <td>9 TB</td>
      <td>26 CAD</td>
      <td>31 CAD</td>
    </tr>
    <tr>
      <td><a href="https://one.google.com/about/plans"><s>Google One</s></a></td>
      <td><s>5 TB</s></td>
      <td><s>5 TB</s></td>
      <td><s>20.83 USD</s></td>
      <td><s>24.99 USD</s></td>
    </tr>
    <tr>
    <tr>
      <td colspan="5">
        <em>Discontinued. Google One doesn't offer more than 2 TB now so
        it's not an option anymore.</em>
      </td>
    </tr>
    <tr>
      <td><a href="https://learn.microsoft.com/en-us/answers/questions/577943/how-to-get-unlimited-onedrive-storage-for-my-enter"><s>OneDrive</s></a></td>
      <td><s>Business (Plan 2)</s></td>
      <td><s>Unlimited</s></td>
      <td><s>65 USD</s></td>
      <td></td>
    </tr>
    <tr>
      <td colspan="5">
        <em>Discontinued. OneDrive only offers up to 1 TB now. They used
        to have unlimited storage if you have 5 or more users with
        "Business (Plan 2)" at 13 USD per user.</em>
      </td>
    </tr>
    <tr>
      <td><a href="https://www.box.com/en-ca/pricing">Box Drive</a></td>
      <td>Business</td>
      <td>Unlimited</td>
      <td>63 CAD</td>
      <td>84 CAD</td>
    </tr>
    <tr>
      <td colspan="5">
        <em>21/28 CAD per user per month but need at least 3 users.</em>
      </td>
    </tr>
    <tr>
      <td><a href="https://mega.io/pricing">MEGA</a></td>
      <td>Pro II</td>
      <td>8 TB</td>
      <td>16.66 EUR</td>
      <td>19.99 EUR</td>
    </tr>
    <tr>
      <td colspan="2"><a href="https://www.backblaze.com/cloud-storage/pricing">Backblaze B2</a></td>
      <td>5 TB</td>
      <td colspan="2">30 USD*</td>
    </tr>
    <tr>
      <td colspan="5">
        <em>*And $0.01/GB to access the data, so that would be 50 USD
        for me to download my entire 5 TB backup once.</em>
      </td>
    </tr>
    <tr>
      <td colspan="2"><a href="https://www.backblaze.com/cloud-backup/pricing">Backblaze Computer Backup</a></td>
      <td>Unlimited</td>
      <td>8.25 USD*</td>
      <td>9 USD*</td>
    </tr>
    <tr>
      <td colspan="5">
        <em>*Per machine. And can only use through their own proprietary
        backup software with serious limitations.</em>
      </td>
    </tr>
    <tr>
      <td colspan="2"><a href="https://www.linode.com/products/object-storage/">Linode Object Storage</a></td>
      <td>5 TB</td>
      <td colspan="2">100 USD*</td>
    </tr>
    <tr>
      <td colspan="5">
        <em>*1 TB outbound transfer included, after that $0.005/GB, so
        that would be 20 USD for me to download my entire 5 TB backup
        once.</em>
      </td>
    </tr>
    <tr>
      <td><a href="https://www.apple.com/ca/icloud/#compare-plans">iCloud</a></td>
      <td>6 TB</td>
      <td>6 TB</td>
      <td colspan="2">39.99 CAD</td>
    </tr>
    <tr>
      <td><a href="https://www.hetzner.com/storage/storage-box/">Hetzner Storage Box</a></td>
      <td>BX21</td>
      <td>5 TB</td>
      <td colspan="2">10.90 EUR</td>
    </tr>
    <tr>
      <td><a href="https://www.hetzner.com/storage/storage-share/">Hetzner Storage Share</a></td>
      <td>NX21</td>
      <td>5 TB</td>
      <td colspan="2">14.19 EUR</td>
    </tr>
  </tbody>
</table>

## Diving in

### Backblaze Computer Backup

Backblaze Computer Backup is incredibly cheap with 9 USD per month for
_unlimited storage_, but keep in mind the price is per machine, and
everything needs to go through their own proprietary backup software. No
Linux support, no way to customize the backup strategy, no way to script
it. The software needs to call home at least once a month otherwise data
gets deleted.

While the backups are encrypted, by default [Backblaze can decrypt them](https://help.backblaze.com/hc/en-us/articles/217664688-Can-you-tell-me-more-about-the-encryption-Backblaze-uses),
however they also provide a way to make the backups end-to-end
encrypted, which is nice.

So if you're fine with the terms and limitations of their backup
software, then it's by far the cheapest option and it seems convenient
to use.

### Box Drive

Another "unlimited storage" option without as many limitations as
Backblaze Computer Backup is Box Drive. It's 63 CAD per month
though so quite a lot pricier. But if you have _a lot_ of data and want
more control over it, that may be very well worth it.

It's even cheaper than the unlimited OneDrive storage that Microsoft was
offering at some point for 65 USD per month.

Box Drive comes with a decent web interface as well as a native app for
macOS, Windows, iPhone and Android.

However keep in mind that it's gonna behave like Dropbox and iCloud:
it's great as a virtual remote drive that has a local copy of some or
all files, but it may not be what you want from a backup solution.

<div class="note">

**Note:** on macOS, the app uses the [Nonreplicated File Provider extension](https://developer.apple.com/documentation/fileprovider/nonreplicated_file_provider_extension)
to provide the syncing.

</div>

As far as encryption goes, it doesn't seem that anything prevents Box to
access your data, so it's something you have to be comfortable with.

### MEGA

Pretty decent option at 16.66 EUR for 8 TB. Like the above, it comes
with an app, and it also supports Linux on top of macOS and Windows!

It's basically a mix of the 2 products mentioned above. You can back up
entire devices to it, but also use it as a shared drive, so that's
pretty neat.

However unlike the Box Drive app, all the files in the synced folder
must be present locally. There's no way to have synced files being on
the server only and being downloaded on demand only when you need them
(and delete just the local copy afterwards).

<div class="note">

**Note:** it seems that MEGA uses its own watching and syncing
algorithm, and they only use macOS's [Finder Sync API](https://developer.apple.com/documentation/findersync)
in order to provide feedback in the Finder UI about whether files are
synced or not.

</div>

So like for Box Drive, if you like the way it behaves, it's a pretty
cheap and convenient solution. If you want more flexibility, they do
offer a SDK but you'll have to write C++. There's also a
[Rclone integration for MEGA](https://rclone.org/mega/) so that's neat
to interact with the storage from the CLI and make something more custom
with it.

In terms of encryption, MEGA seems pretty solid because everything is
end-to-end encrypted with a key derived from your account password. If
you forget your password and recovery key, you're out of luck, but that
also means MEGA can't read your data. Thumbs up for me.

### Hetzner Storage Box

At 10.90 EUR for 5 TB, it's the cheapest option here to be _actually_
flexible. You don't need a proprietary app to use it. Instead it
supports the following [protocols](https://www.hetzner.com/storage/storage-box/):

* FTP
* FTPS
* SFTP
* SCP
* Samba/CIFS
* BorgBackup over SSH
* Restic over SSH
* Rclone over SFTP
* rsync over SSH
* HTTPS
* WebDAV

This is quite impressive, as it supports a number of popular backup
software, so unlike the options above, you don't need to use a backup
or syncing software made by the storage provider. Hetzner only does the
storage (and does it well), and you can use the backup or syncing
software of your choice, whose only focus is to do just that (and do it
well). Now we're talking.

Most of those protocols are gonna be useful for listing, retrieving and
uploading files, and the few options "over SSH" are gonna be
particularly performant at incremental backups.

While backup and syncing software often have an option to working over
SFTP or similar, it's usually pretty inefficient when you need to diff
the local and remote state in order to upload only what changed.

However, when paired with a companion command on the server, like is the
case with BorgBackup, Restic and rsync above, the process can be much,
much more efficient, because the client/server programs can exchange
just the minimum amount of metadata in order to determine what changed
and what needs to be transferred.

**This makes the Hetzner Storage Box a killer option if you're gonna use
one of those natively supported options above.**

The encryption is gonna depend on the protocol you use. The files are
obviously stored encrypted on disk, and everything but FTP will transfer
the files encrypted, however only BorgBackup and Restic actually perform
end-to-end encryption of the files (meaning that Hetzner can't decrypt
them).

If you want to use any other protocol and also want end-to-end
encryption, you can still implement it yourself as another layer. See
more [in the next article](offsite-backup-sync.md). 😉

### Hetzner Storage Share

A bit pricier than the Storage Box at 14.19 EUR for 5 TB, and the use
case is a bit different. It's a hosted
[Nextcloud](https://nextcloud.com/) instance.

They have an app for Windows, macOS and Linux, as well as mobile apps. I
only tried the macOS app and it acts as a shared folder just like
Dropbox would.

At the time of writing, the desktop app will download all the files
locally, [there's no way](https://help.nextcloud.com/t/mac-desktop-client-dont-download-files-only-show-the-files/101987/4)
to browse the remote data without downloading everything locally first.
For me and my 5 TB, that's a problem.

Also keep in mind Nextcloud [doesn't support end-to-end encryption](https://help.nextcloud.com/t/end-to-end-encryption-zero-knowledge/172209).

So the Hetzner Storage Share looks like a pretty sweet option with a
decent price if you want a synced folder, but it doesn't cut it for my
backups.

## Bonus: why not GCP and AWS?

[Google Cloud Platform](https://cloud.google.com/) and [Amazon Web Services](https://aws.amazon.com/)
both offer solutions that could help. So you may wonder why I'm not
considering a pure cloud storage service like [GCS](https://cloud.google.com/storage)
or [S3](https://aws.amazon.com/s3/), or alternatively, a VM with
persistent disk on [GCE](https://cloud.google.com/products/compute) or
[EC2](https://aws.amazon.com/ec2/).

Well, I did consider those option, that's actually the one I
professionally work with most of the time, but they definitely did not
fit the bill for my personal usage.

### GCS/S3

As usual with cloud computing, the pricing is hard to predict. Not
because the pricing model is unpredictable _per se_ (although it's
complex, it's also relatively clear). But because my potential usage is
unpredictable without gathering data by running real-world simulations.

GCS and S3 charge not only for the amount of data stored, but also the
read/write operations and download bandwidth.

Depending on the selected storage class, either the storage itself is
expensive but reading/writing and downloading are relatively cheap, or
the storage is cheap but reading/writing and downloading gets much, much
more expensive.

GCS and S3 are pretty similar for this in pricing. So for my 5 TB, I
could either:

* Pay $100 per month for storage and spend $15 to download my entire backup.
* Pay $50 per month for storage and spend $50 to download my entire backup.
* Pay $20 per month for storage and spend $200 to download my entire backup.

And it's not a precise number because it's really, really hard to
predict how many operations I will actually use. And it would be totally
possible that I'm missing some egress bandwidth fee on top of what's
already factored in the data retrieval fees, and it could easily
surprise bump the bill by something like $400 in case of downloading the
entire backup.

Not down to take the risk.

### GCE/EC2 VM

On GCE, it would cost ~$200 per month for a 5 TB HDD. Downloading the
entire backup would cost $400.

On EC2, that would be ~$80 per month for a 5 TB HDD, and $500 to
download the entire backup.

Not in my price range _at all_.

## Conclusion

The [Hetzner Storage Box](#hetzner-storage-box) was by far the best
option for me. It's pretty cheap, and offers a ton of flexibility with
SFTP access as well as support for a number of protocols like rsync,
Restic and BorgBackup. End-to-end encryption comes for free with Restic
and BorgBackup, and can still be implemented "manually" otherwise.

All the other storage providers require a specific app that can't be
customized to my needs, except for the [cloud providers](#bonus-why-not-gcp-and-aws)
that are even more flexible but also insanely more expensive (and whose
pricing model can easily result in very costly surprises).

Also except for MEGA and Backblaze Computer Backup (as an option), the
other solutions don't support end-to-end encryption.

So I subscribed for a 5 TB Hetzner Storage Box. Now, let's see how I
[implemented end-to-end encryption and syncing](offsite-backup-sync.md)
with it!

<div class="note">

1. Encrypted offsite backup system: storage 💾
1. [Encrypted offsite backup system: syncing 📲](offsite-backup-sync.md)

</div>
