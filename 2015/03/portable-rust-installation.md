# Portable Rust installation
March 15, 2015

The [recommended Rust installation method][install] is to
curl a `rustup.sh` script and pipe it into `sh`. The script will then
ask for `root` permissions and install stuff globally. You'll never see
me pipe unknown stuff from the network into `sh`.

> I don't get that new `curl foodotcom/setup | sh` trend, do you want to
> fuck up your OS? Because that's how you fuck up your OS.
>
> --- [@iMilnb](https://twitter.com/iMilnb) [March 15, 2015](https://twitter.com/iMilnb/status/577229798910611456)

[install]: http://www.rust-lang.org/install.html

And even when manually downloading and extracting the binaries, we still
need to run a 1000 lines `install.sh` script doing again stuff as
`root`.

However, it turns out to be trivial to use Rust without installing
anything globally, nor running big shell scripts as `root`.

First, get the binaries according to your system, and the Rust version
you want. For me (nightly 64-bit Linux binaries) and extract the archive
(I like to put it in `~/opt`):

```sh
wget https://static.rust-lang.org/dist/rust-nightly-x86_64-unknown-linux-gnu.tar.gz
tar xf rust-nightly-x86_64-unknown-linux-gnu.tar.gz
mv rust-nightly-x86_64-unknown-linux-gnu rust
```

Then, just export the appropriate environment variables (do this from
your `~/.profile` or equivalent to have it set up automatically). No
need to install anything globally!

```sh
export LD_LIBRARY_PATH=~/opt/rust/rustc/lib:$LD_LIBRARY_PATH
export PATH=~/opt/rust/rustc/bin:$PATH
export PATH=~/opt/rust/cargo/bin:$PATH
```
