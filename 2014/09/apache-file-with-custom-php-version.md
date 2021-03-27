# Apache file with custom PHP version
September 16, 2014

I once wanted to execute a single PHP file with a specific PHP version,
different from the globally configured one with `mod_php`.

First, enable a `cgi-bin` directory:

```apache
<Location "/cgi-bin">
  SetHandler cgi-script
  Options +ExecCGI
<Location>
```

You can also use `ScriptAlias` for this.

Then, for this specific file, turn off `mod_php` and use custom CGI:

```apache
<Location "/test.php">
  php_flag engine off
  Action php-cgi /cgi-bin/php55
  AddHandler php-cgi .php
<Location>
```
