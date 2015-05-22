FreeBSD, Python and SSL certificate validation
==============================================
May 22, 2015

When not explicitely giving a SSL certificate file to Python `request`,
it will expect the system certificates to be in `/etc/ssl/cert.pem`.

However, in FreeBSD, they are in `/usr/local/etc/ssl/cert.pem`,
resulting in the following error:

```
urllib.error.URLError: <urlopen error [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:600)>
```

The quick and dirty fix for this was the following:

```sh
ln -s /usr/local/etc/ssl/cert.pem /etc/ssl/cert.pem
```

Now Python can find the system certificates, and we don't need to
explicitely give the certificate file to `request` when doing the
request (espacially useful when `request` is used by another module that
don't allow to customize the certificates).
