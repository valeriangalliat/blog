Debian recursive purge
======================
October 7, 2014

When running an `aptitude purge <package>`, unlike with `remove`, the
package's configuration files will also be purged.

However, while in both cases the unneeded dependencies are removed,
they're not recursively purged when using `purge`. This results in all
`<package>` dependencies configuration files remaining on the system
(and there can be a lot if you [install recommendations and suggestions][clean],
which is the default).

[clean]: ../../2014/09/keeping-debian-clean-and-minimal.md

While I don't know a way to make `purge` recursively purge the
dependencies configuration files, you can run `aptitude purge '~c'` to
remove the configuration files of **all previously removed (but not
purged) packages**.

See also [aptitude search patterns][search] for all the neat stuff
you can use in aptitude queries!

[search]: https://aptitude.alioth.debian.org/doc/en/ch02s04s05.html
