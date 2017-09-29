Command invocation over TCP with socat
======================================
April 19, 2015

I wanted to run a TCP server in a Docker container, invoking given
command in a child process upon each request. This way, I could run a
Docker *service* container once, and send it parallel TCP requests to
run a specific command over some input, instead of having to invoke the
container each time I want to call the command.

[More][parallelism-1] on the [actual issue][parallelism-2] (see "Parallelism").

[parallelism-1]: https://github.com/sass-compatibility/sass-compatibility.github.io/pull/36#issuecomment-94303270
[parallelism-2]: https://github.com/sass-compatibility/sass-compatibility.github.io/pull/36#issuecomment-94271213

First try with Ncat
-------------------

I originally thought of [Ncat][] (that comes with [Nmap]) for this job. Ncat
is an awesome netcat-like utility with some additions, particularly SSL
support, the ability to handle multiple clients, and to run a program to
handle each connection.

[Ncat]: https://nmap.org/ncat/
[Nmap]: http://nmap.org/

I ended up with the following invocation:

```sh
# Server
ncat --listen --keep-open --sh-exec my-command 1337

# Client
echo some data | ncat localhost 1337
```

But this didn't work as expected. While everything was fine when running
`ncat localhost 1337` interactively, I just had no output when piping to
Ncat. I expected Ncat to **wait for the output**, and it really felt
like a bug. I ended up digging into the code to understand this.

I found [this interesting comment](https://github.com/nmap/nmap/blob/5adfb3b1de162b5fc14b89f5383989af049eb745/ncat/ncat_posix.c#L259-L262)
in the function handling server command execution:

> Enter a "caretaker" loop that reads from the socket and writes to the
> subprocess, and reads from the subprocess and writes to the socket.
> **We exit the loop on any read error (or EOF).** On a write error we
> just close the opposite side of the conversation.

Ha! Ncat is stopping everything when the input is consumed, even if the
command *output* haven't reached EOF yet. And there is no option to
control this behavior, damned!

socat to the rescue
-------------------

[socat](http://www.dest-unreach.org/socat/) can do all what Ncat can do,
but also way much more.

Here's the working socat version:

```sh
# Server
socat -t 10 TCP-LISTEN:1337,reuseaddr,fork SYSTEM:my-command

# Client
socat -t 10 TCP:localhost:1337 -
```

This is basically doing the same as the previous Ncat invocations, but
with the `-t 10` added.

Without this option, socat behaves nearly exactly like Ncat: it waits
0.5 seconds for output after the input reaches EOF, and exit regardless
the output reached EOF (while Ncat exits *instantly* upon input end).
`-t 10` tells socat to wait 10 seconds (instead of the 0.5 default) for
the other part of the channel to finish once the first part is done.

Exactly what I needed!

appendix
--------

Alternatively, socat provides an `ignoreeof` option that will keep the port open until the command returns. This may be indefinite if the command stalls, and therefore using the timeout option may be preferable in many cases. 

```sh
# Server
socat TCP-LISTEN:1337,reuseaddr,fork,ignoreeof SYSTEM:my-command

# Client
echo some data | nc 127.0.0.1 1337
```
