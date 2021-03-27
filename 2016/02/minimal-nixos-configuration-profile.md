# Minimal NixOS configuration profile
February 15, 2016

I found that by default, NixOS comes with some X11 libraries and
a bunch of fonts.

```
/nix/store/0gj8wawx2zafi5jamal4rhh35hs1lxkg-font-bh-100dpi-1.0.3
/nix/store/2snhxh1bs0p6qwks7qgvkmibscyz1v07-libICE-1.0.9
/nix/store/3kgsyqzk4h5h0ry3b9mx5qxk0gzzffb0-xproto-7.0.28
/nix/store/3ww7iljg87q76xslr0bjnb4iyks9vba7-libSM-1.2.2
/nix/store/4mp635p6jy2wqab2y23gcnm4nka27snb-kbproto-1.0.7
/nix/store/5kicd5g9w5fnn10zv6v3f3j63g2r4c72-paxctl-0.9
/nix/store/5pqjb96k827y8b3df8dxx71ywd7icm6d-libXext-1.3.3
/nix/store/85h3bld5s471kn5wnzwvkiasny9id2l3-libXmu-1.1.2
/nix/store/8v7ap2190cmj9vb43hdjjqi5y65325gc-font-bh-lucidatypewriter-75dpi-1.0.3
/nix/store/a4vjc9rvhvyv6cg8518sfis26i2zg5gi-libXdmcp-1.1.2
/nix/store/arqx594bc4k3l9w2laximxllny2l7zwv-libXau-1.0.8
/nix/store/b62bjdfxcqaa7y8yi94lrwrbd8jrxhpg-dejavu-fonts-2.35
/nix/store/bnh38lyxrpvw477pl6aj2hbyjfy11kgi-font-cursor-misc-1.0.3
/nix/store/bskdx85qy4zmk6ipkn6jii086cqqml5b-libXt-1.1.5
/nix/store/cx5g5f31hxqn5wpibb965jc82if9b4ch-xauth-1.0.9
/nix/store/fy5wr7iiiwkp97x4kw3c0a10v48qwnsh-font-bh-lucidatypewriter-100dpi-1.0.3
/nix/store/j8fjm1q3js8klv3kj7p25s59gnxlj9bc-xextproto-7.3.0
/nix/store/jz48a2dpwnv3in2z33p2a48z9plgggx3-fonts.conf
/nix/store/kvb8lwgzzswl4p7g8lax7jl67fzmpj0f-fontconfig-ultimate-20141123
/nix/store/l15rppxw3fjyysslj160q31jc7pkqb32-patchelf-0.8
/nix/store/lk6r8kmbbqrcs6j0sg2vg20rl68mhalx-unifont-8.0.01
/nix/store/m1vz15w0f4wkcnw9l4xvbswiimdawf3j-liberation-fonts-2.00.1
/nix/store/m26x6xijsxsf3gmjjz9z17xmflb2mw1s-freefont-ttf-20120503
/nix/store/p73fhs21mai1akmk4z6y3ax6kpv4zmy5-libX11-1.6.3
/nix/store/pz4yfw93q94gam2qv42ylr471bg0y5pi-font-alias-1.0.3
/nix/store/q0p5y96wqmy6mq32y5g3qpqnrk1pbkcv-fontconfig-2.10.2
/nix/store/vs9shdrh50iaqmrrph92gk8pmfg9chwp-libxcb-1.11.1
/nix/store/wc79xwb4vxfzadam5rva5iz1gyqd6fw6-font-misc-misc-1.1.2
```

I don't expect this on my system when I'm, for example, configuring a
headless server.

When searching about this issue, I discovered the
`<nixpkgs/nixos/modules/profiles/minimal.nix>` file, that disables just
all of this!

The magic line to put in your system configuration:

```nix
{ config, pkgs, ... }:

{
  # ...

  imports = [ <nixpkgs/nixos/modules/profiles/minimal.nix> ];

  # ...
}
```
