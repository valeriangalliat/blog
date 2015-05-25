Apache get PHP version from environment
=======================================
Aug 19, 2014

Using [phpfarm] to compile custom PHP versions.

[phpfarm]: https://github.com/cweiske/phpfarm

With the following structure:

```
/home/site
├── cgi-bin
│   └── php-cgi
└── phpfarm
    └── inst
        ├── bin
        │   ├── php-cgi-5.5
        │   └── php-cgi-5.6
        └── current-bin
            └── php-cgi
```

The `cgi-bin/php-cgi` script:

```sh
#!/bin/sh -e

cd "$(dirname "$0")"

inst=../phpfarm/inst

if [ -z "$PHP_VERSION" ]; then
    file="$inst/current-bin/php-cgi"
else
    file="$inst/bin/php-cgi-$PHP_VERSION"
fi

exec "$file"
```

And the Apache configuration:

```apache
DocumentRoot /home/site/public_html
ScriptAlias /cgi-bin-php/ /home/site/cgi-bin/

AddHandler php-cgi .php
Action php-cgi /cgi-bin-php/php-cgi
```

The PHP version will be executed according to the `PHP_VERSION`
environment variable, that you can set for example from a `.htaccess`:

```apache
SetEnv PHP_VERSION 5.6
```

Variant: PHP version at project level
-------------------------------------

If you don't need this to be configurable at environment level, you can
simply configure the PHP version in the virtual host:

```apache
DocumentRoot /home/site/public_html
ScriptAlias /cgi-bin-php/ /home/site/cgi-bin/

<Location /project-5.5>
  AddHandler php-cgi .php
  Action php-cgi /cgi-bin-php/php-cgi-5.5
</Location>

<Location /project-5.6>
  AddHandler php-cgi .php
  Action php-cgi /cgi-bin-php/php-cgi-5.6
</Location>
```

Where `php-cgi-5.5` contains the following (and similar for
`php-cgi-5.6`):

```sh
#!/bin/sh
exec /home/php/phpfarm/inst/bin/php-cgi-5.5
```
