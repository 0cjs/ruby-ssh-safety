Demonstrate Safe Use of Ruby's Net::SSH
=======================================

Introduction
------------

#### The Host Key Problem

Using SSH safetly requires a bit more than just connecting to a host
and accepting whatever happens. In particular, to prevent [MITM]
(man-in-the-middle) attacks you need to ensure you know the host's SSH
public key in advance and verify that the host to which you're
connecting has the corresponding private key.

[MITM]: https://en.wikipedia.org/wiki/Man-in-the-middle_attack

This can be tricker than it sounds because the SSH protocol and most
of its implementations have a convenience feature: the host to which
you're connecting sends you its public key which you can then verify.
If you don't already have the public key in your local database, most
SSH implementations have an option, often enabled by default, that
lets you accept that key and then verify the server has the
corresponding private key.

The problem is, of course, an attacker can send you any public key he
likes. If you don't have your own copy of the public key you expect,
or at least its fingerprint, and you accept that public key, you may
well be accepting an attacker's public key. He can now proxy your
connection on to the real host, reading and modifying all your data at
will.

OpenSSH has a configuration directive called `StrictHostKeyChecking`
which, when set to `yes` will assert that for the host to which you
are trying to connect there is an entry in the local database of host
keys for that host that matches the key that the server offers. If
such an entry does not exist, it aborts the connection with an error.
(You are expected to confirm the host key, typically out of band, and
add it to the database if it's correct.)

#### (One of the) Problems with Net::SSH

The details are all described in the Ruby file, but we summarize the
problem here. [Net::SSH] by default uses what it calls a "strict" host
key verifier. This is rather misleading since this does _not_ do what
OpenSSH's `StrictHostKeyChecking yes` configuration directive does; in
fact it does rather the opposite. Using "strict" verification,
Net::SSH will happily accept keys not in the local database and even
try to add them to the local user's database if that's writable.

[Net::SSH]: https://github.com/net-ssh/net-ssh

Obviously this is insecure, and also using a database external to your
program (`/etc/ssh/ssh_known_hosts` and `$HOME/.ssh/known_hosts` on
Unix) also makes deployment and security analysis more difficult. The
best thing to do is to embed the keys of the hosts to which you connect
in your program code or in a file or database that goes along with your
program as part of the deployment process.

The code here demonstrates how to configure Net::SSH to connect in a
more secure manner, and includes extensive comments on how how
Net::SSH works by default and what we need to change in our usage of
it. It's not meant to be production code; you'll need to integrate
this in to your own system in whatever way you see fit. However, I
recommend that you have a wrapper class that handles connectivity for
all parts of you code and you implement a mechanism to warn
programmers when they try to use `Net::SSH` directly rather than using
your code that uses a more secure configuration.


Usage
-----

Read and understand the code in [Example.rb].

You can run the file and it should demonstrate that various conection
configurations produce the expected results.

#### Environment

I run Ruby from [rbenv](https://github.com/rbenv/rbenv); I have a
`.ruby-version` file here indicating version 2.3.1 because that
happens to be an environment where this will likely be used. In this
project I also use [Bundler](https://bundler.io/) to get the correct
versions of Gems.

After setting up `rbenv` and installing 2.3.1, you can set up the rest
of the environment with the usual:

    gem update --system
    gem install bundler
    bundle install

#### Net::SSH Version

I currently use 3.2.0, the latest stable version. Depending on how
things progress both on my exploration of the 3.2 API and the release
process of 4.0.0, I may change to using 4.x sooner or later.
