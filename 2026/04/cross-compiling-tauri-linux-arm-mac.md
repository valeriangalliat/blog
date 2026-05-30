---
tweet: https://x.com/valeriangalliat/status/2044190593543483532
---

# Cross-compiling a Tauri app for x86-64 Linux from an ARM Mac (no emulation ⚡️)
April 14, 2026

Context: I'm building an app called [Flame](https://useflame.app/)
with [Tauri](https://v2.tauri.app/), and I work from a M-series Mac.

We initially released it only on Mac as a MVP. Some folks on Reddit
showed interest but were on Windows and Linux. I'm pretty eager to get
more hands on the product in those early stages, to gather feedback and
learn from users where to take it from there, so making it cross
platform early on sounded like a quick win.

## Quick note on the Windows build

Not the topic of this post but I might as well throw that here in case
it's useful to anyone. Building for Windows from Mac turned out pretty
easy following [this guide](https://v2.tauri.app/distribute/windows-installer/#build-windows-apps-on-linux-and-macos).
In short:

```sh
brew install nsis llvm
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
rustup target add x86_64-pc-windows-msvc
cargo install --locked cargo-xwin
export PATH="$HOME/.cargo/bin:$PATH"
tauri build --runner cargo-xwin --target x86_64-pc-windows-msvc
```

This works like a charm, signed auto updates and all.

Signing the app to avoid the SmartScreen warning is not handled out of
the box by Tauri when cross-compiling (it only knows to use
`signtool.exe` from a Windows host), but you can configure a custom
signing command like [osslsigncode](https://github.com/mtrojnar/osslsigncode)
and do it from Mac or Linux as well (I haven't tried it).

## What about GitHub Actions

Yeah honestly, should have just done that. I got nerd sniped by wanting
to compile for all platforms from my own machine without renting
hardware in the cloud. And the idea of generating a working x86-64
Windows and Linux build from my ARM Mac with near-native build
performance (so without using QEMU) sounded kinda cool to me.

But really, Tauri has [everything ready to use GitHub Actions](https://v2.tauri.app/distribute/pipelines/github/)
and output binaries for all platforms, it's a no brainer.

And the free tier for GitHub Actions is high enough that unless you're
releasing updates every other day, you probably won't need to pay for
it? The Mac runner is by far the most expensive so you could also go a
long way building for Mac from your dev machine and delegating only
Windows and Linux to GitHub Actions.

## OK but I'm here for cross-compiling Linux, remember?

Oh yeah, sorry. I got distracted. 😂

The strategy:

* **Use macOS Virtualization framework to run a ARM Linux
  VM at near-native performance.**
* **Inside that VM, configure Linux to cross-compile the app for
  x86-64.**
* **Use Rosetta from Linux (yeah this is a
  thing) to run any x86-64 binaries we need along the way at also
  near-native performance.**

## Creating the VM with Lima

We use [Lima](https://lima-vm.io/) to manage a headless Linux VM.

```sh
brew install lima

limactl create --name=linux-builder \
    --vm-type=vz --rosetta \
    --cpus=6 --memory=8 --disk=60 \
    --containerd=none

limactl start linux-builder
```

* [`--vm-type=vz`](https://lima-vm.io/docs/config/vmtype/vz/) to make
  sure we use macOS Virtualization framework. It's the default in Lima
  but we're explicit about it.

  Virtualization framework only works for same-architecture VMs, so here
  we're making an ARM Linux VM, even though we want to build for x86-64.
* [`--rosetta`](https://lima-vm.io/docs/config/multi-arch/#fast-mode-2)
  to use Apple Rosetta to translate x86-64 instructions to ARM on the
  fly, for binaries we run inside the VM.
* `--containerd=none` because we don't need containerd (not running
  Docker here).

## Provisioning the VM

Now we'll run a shell inside the VM to provision it with everything we
need to cross-compile a Tauri app.

```sh
limactl shell linux-builder
```

### Add AMD64 architecture

```sh
# No interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Enable AMD64 multi-arch
sudo dpkg --add-architecture amd64

# VM defaults to `ports.ubuntu.com` which only has ARM64 sources.
# We need to add `archive.ubuntu.com` for AMD64.
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

sudo tee /etc/apt/sources.list.d/ubuntu-amd64.list > /dev/null << EOF
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${CODENAME} main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${CODENAME}-updates main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${CODENAME}-backports main restricted universe multiverse
deb [arch=amd64] http://security.ubuntu.com/ubuntu ${CODENAME}-security main restricted universe multiverse
EOF

# Constrain the native sources to ARM64 so APT doesn't try to fetch
# AMD64 packages from it.
sudo sed -i '/^Architectures:/d' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i 's/^Types: deb/Types: deb\nArchitectures: arm64/' /etc/apt/sources.list.d/ubuntu.sources

sudo apt update
```

### Install system dependencies

```sh
PKGS="git ca-certificates"

# Tauri prerequisites from <https://v2.tauri.app/start/prerequisites/#linux>.
# Added AMD64 suffix for cross-compilation.
PKGS="$PKGS
build-essential curl wget file
libwebkit2gtk-4.1-dev:amd64 libxdo-dev:amd64 libssl-dev:amd64
libayatana-appindicator3-dev:amd64 librsvg2-dev:amd64"

# Tauri needs the AMD64 version of `xdg-open` to bundle in the app
PKGS="$PKGS xdg-utils:amd64"

# Cross-compilation toolchain
PKGS="$PKGS gcc-x86-64-linux-gnu g++-x86-64-linux-gnu"

sudo apt install -y --no-install-recommends $PKGS
```

### Install Rust

Native ARM Rust with x86-64 cross-compilation target.

```sh
# `sh -s` to force reading from stdin and allow passing arguments without a
# filename. Configure the installer to be non-interactive (default yes) not
# modify the # `PATH` (we do it ourselves) and install stable.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --default-toolchain stable

echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.profile
export PATH="$HOME/.cargo/bin:${PATH}"

rustup target add x86_64-unknown-linux-gnu
```

### Install Node.js

I like to use [asdf](https://asdf-vm.com/) for this.

```sh
ASDF_URL=$(curl -fsS https://api.github.com/repos/asdf-vm/asdf/releases/latest \
    | grep -o '"browser_download_url": *"[^"]*linux-arm64\.tar\.gz"' \
    | grep -o 'https://[^"]*')

curl -fsSL "$ASDF_URL" | sudo tar -xz -C /usr/local/bin asdf

echo 'export ASDF_DATA_DIR="$HOME/.asdf"' >> ~/.profile
echo 'export PATH="$ASDF_DATA_DIR/shims:$PATH"' >> ~/.profile

export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="$ASDF_DATA_DIR/shims:$PATH"

asdf plugin add nodejs

# Optionally pnpm or whatever package manager you use
# asdf plugin add pnpm

# Assuming we already have a `.tool-versions`
asdf install
```

### Rosetta AppImage support

This was the biggest culprit of this whole setup.

Tauri build uses [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy)
to build AppImages, and linuxdeploy itself is distributed as an
[AppImage](https://en.wikipedia.org/wiki/AppImage).

Lima with `--rosetta` configures `binfmt_misc` to use Rosetta for a
particular ELF signature. However their pattern is not compatible with
AppImages.

Normal ELF format normally uses `0x00 0x00` for bytes 8-9
(`EI_ABIVERSION` and the start of `EI_PAD`), but the [AppImage format](https://github.com/AppImage/AppImageSpec/blob/master/draft.md#image-format)
repurposes them as a magic identification bytes "AI" (`0x41 0x49`).

We need to patch [Lima's `binfmt_misc` pattern](https://github.com/lima-vm/lima/blob/10d0287227bfdd067dfd770cf4977a4fa9ac8c21/pkg/driver/vz/boot.Linux/05-rosetta-volume.sh#L20)
to handle this so we can use Rosetta for x86-64 AppImages like the
linuxdeploy one.

Here's the ELF [identification bytes](https://refspecs.linuxfoundation.org/elf/gabi4+/ch4.eheader.html#elfid):

| Name            | Offset | Purpose                             |
|-----------------|--------|-------------------------------------|
| `EI_MAG0`       | 0      | File identification                 |
| `EI_MAG1`       | 1      | File identification                 |
| `EI_MAG2`       | 2      | File identification                 |
| `EI_MAG3`       | 3      | File identification                 |
| `EI_CLASS`      | 4      | File class                          |
| `EI_DATA`       | 5      | Data encoding                       |
| `EI_VERSION`    | 6      | File version                        |
| `EI_OSABI`      | 7      | Operating system/ABI identification |
| `EI_ABIVERSION` | 8      | ABI version                         |
| `EI_PAD`        | 9      | Start of padding bytes              |
| `EI_NIDENT`     | 16     | Size of `e_ident[]`                 |

Lima's mask is strict on `EI_ABIVERSION` and `EI_PAD`, and this causes
it to exclude AppImage binaries. We can change the mask to ignore those
bytes and match AppImages.

<details>
<summary>Show the bytes table</summary>

| Offset | Before   | After    |
|--------|----------|----------|
| 0      | `ff`     | `ff`     |
| 1      | `ff`     | `ff`     |
| 2      | `ff`     | `ff`     |
| 3      | `ff`     | `ff`     |
| 4      | `ff`     | `ff`     |
| 5      | `fe`     | `fe`     |
| 6      | `fe`     | `fe`     |
| 7      | `00`     | `00`     |
| **8**  | **`ff`** | **`00`** |
| **9**  | **`ff`** | **`00`** |
| **10** | **`ff`** | **`00`** |
| **11** | **`ff`** | **`00`** |
| **12** | **`ff`** | **`00`** |
| **13** | **`ff`** | **`00`** |
| **14** | **`ff`** | **`00`** |
| **15** | **`ff`** | **`00`** |
| 16     | `fe`     | `fe`     |
| 17     | `ff`     | `ff`     |
| 18     | `ff`     | `ff`     |
| 19     | `ff`     | `ff`     |

</details>

```sh
sudo tee /etc/binfmt.d/rosetta.conf > /dev/null << EOF
# Ignore \`EI_ABIVERSION\` and \`EI_PAD\` for AppImage support
:rosetta:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xfe\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\xff\xff\xff:/mnt/lima-rosetta/rosetta:OCF
EOF

# Re-read all `binfmt.d` entries to activate the new rule immediately
sudo systemctl restart systemd-binfmt
```

## Building the AppImage

The VM is now provisioned. The following we run for every build.

First, we sync the code in a VM-private directory, because we don't want
the Linux `node_modules` installation to mess up our macOS host
`node_modules`.

```sh
VM_APP_DIR="/home/$USER.guest/my-app"

limactl shell linux-builder -- rsync -a --delete \
    --exclude='node_modules' \
    --exclude='src-tauri/target' \
    ./ "$VM_APP_DIR/"
```

If we're signing the build and `TAURI_SIGNING_PRIVATE_KEY` refers to a
file on the host side, we need to convert it to a plain string so the VM
has access.

```sh
if [ -f "${TAURI_SIGNING_PRIVATE_KEY}" ]; then
    TAURI_SIGNING_PRIVATE_KEY="$(cat "$TAURI_SIGNING_PRIVATE_KEY")"
fi
```

Then we set cross-compilation environment variables, and configure Lima
to forward them to the VM.

```sh
export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc

# We force AppImages to extract to a temp dir instead of FUSE-mounting, because
# the kernel's `compat_ioctl` layer does not fully translate x86-64 FUSE ioctls
# to ARM64. This allows to run x86-64 AppImages like linuxdeploy.
export APPIMAGE_EXTRACT_AND_RUN=1

export LIMA_SHELLENV_ALLOW="PKG_CONFIG_ALLOW_CROSS,PKG_CONFIG_PATH,CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER,TAURI_SIGNING_PRIVATE_KEY,TAURI_SIGNING_PRIVATE_KEY_PASSWORD,APPIMAGE_EXTRACT_AND_RUN"
```

Install dependencies (adapt to your package manager).

```sh
limactl shell --workdir="$VM_APP_DIR" linux-builder -- pnpm install
```

Actually build.

```sh
limactl shell --preserve-env --workdir="$VM_APP_DIR" linux-builder -- \
    pnpm exec tauri build "$@"
```

Finally copy the artifacts back to host.

```sh
BUNDLE_DIR="src-tauri/target/x86_64-unknown-linux-gnu/release/bundle/appimage"

mkdir -p "$PWD/$BUNDLE_DIR"

limactl copy --recursive \
    "linux-builder:$VM_APP_DIR/$BUNDLE_DIR/" \
    "$PWD/$BUNDLE_DIR/"

version=$(jq -r '.version' app/package.json)

for f in "$BUNDLE_DIR/"*"_${version}_amd64.AppImage"*; do
    echo "  $PWD/$f"
done
```

## Wrapping up

Mainly because of the Lima default Rosetta `binfmt_misc` mask that
rejects AppImages magic bytes, this was harder than I expected.

Again, should have really just used GitHub Actions for that. 😅

But hey, this was kinda fun, and I find it "aesthetic" to be able to
make a x86-64 Linux build from an ARM Mac without emulation.
