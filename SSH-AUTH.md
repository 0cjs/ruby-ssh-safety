SSH Keys and Authentication
===========================

This is a very brief introduction that concentrates more on "what the
different keys are" than how public key cryptography works. It also
ignores some details for the sake of brevity. For a full beginner's
introduction (and a lot of useful information even for those with good
knowledge of this area) you might have a look at [Cryptography for
Practitioners][SSH-crypto].

If you are already familiar with PK schemes, feel free to skip the
[Asymmetric Cryptography](#asymmetric-cryptography) section just
below, but do at least give a quick scan to the [SSH
Authentication](#ssh-authentication) and subsequent sections below.


Asymmetric Cryptography
-----------------------

The standard encryption/decryption schemes we first learn about (such
as AES-256) are symmetric: that is, there's one secret that both
parties hold, and that secret will both encrypt plaintext into
cyphertext and decrypt that cyphertext back into plaintext. This
introduces two problems: 1) you have to ensure that both sides, not
just one, are trustworthy enough to take care of the key, and, 2)
often much more difficult, you need to securely communicate the key
between the two sides. 2) might not seem so hard until you consider
how you handle this when the other side is a different company where
nobody has a personal relationship with anybody in your company.

This is where asymmetric cryptography, sometimes referred to as
"public-key encryption" or "PK" can be useful. In this case the key
comes in two parts (often referred to as a "keypair"), the public key
_e_ and the private key _d_.  A message encrypted with _e_ can be
decrypted only with _d_, allowing anybody with the public key to
create messages that only the private key holder can read. The
reverse, encrypting with _d_, can (through a complex process) allow
anybody with the public key _e_ to verify that the message was created
by someone holding the private key _d_. This can be used as part of an
authentication technique to verify that you're communicating with
someone holding the private key.

This authentication technique can also be used to "sign" messages,
which is used in [PKI] systems that allow one to verify the validity
of a public key one hasn't seen before. SSH can use this, but it's
complex and rare and we don't discuss it further here.

One further note: this explanation is intended to give a general idea
of how asymmetric cryptography works, but it's not entirely correct on
some important details. Thus you must _not_ use this as a guide to
building or analysing cryptosystems.


SSH Authentication
------------------

As described in Wikipedia's [SSH Architecture] summary and in more
detail in [RFC 4251], setting up an SSH connection proceeds in several
stages and involves two different kinds of authentication.

   1. The client authenticates the server, that is, confirms it's
   connecting to the real server rather than in impostor. To do this,
   the client must already know a public key for the host (hosts may
   have more than one), or at least have a key's fingerprint.

   2. The server authenticates and authorizes the client. The client
   usually gives a username and either provides a password or proves
   that it holds a private key for which the server has a corresponding
   public key.

   3. If the client successfully authenticates to the server, the
   server decides what access to allow and both sides run their
   protocols (terminal sessions, SFTP sessions, agent forwarding,
   etc.) within the SSH transport session.


Different SSH Keypairs
--------------------------

There are three keypairs (or just "keys" from these pairs) you'll
commonly encounter when dealing with an SSH session: the server host
key, the client host key and the client (user) key. These are all
separate things used for different purposes; avoid confusing them.
There are often several different keys of each type in various formats
(such as RSA, ECDSA and so on); any one that both the client and
server know and understand can be used.

#### Server Host Key

The server's host key is the most critical one, and is required to set
up a connection. The public part of this key is effectively the
identity of the server.

The server will send its host public key as part of the connection
setup.  However, this alone is not useful to identify the server since
an attacker can send any key he likes. For the authentication process
to work the client must not only verify that the server has the
private key corresponding to the public key (which is done
automatically by the protocol) but must also verify that the public
key is correct. This is typically done by comparing the public key to
a locally stored copy of the expected public key.

The OpenSSH client looks these up in various `known_hosts` files; the
format is described in the [sshd] manpage and the settings for the
global and user known hosts files are described in the [ssh_config]
manpage. Ruby's `Net::SSH` client is more or less compatible with
this, but you probably don't want to rely on files like this external
to your application because they're very hard to audit and verify;
thus, the procedure to use your own key database as described in
[README.md] and [Example.rb].

#### Client Host Key

Many client hosts can also function as servers, and have their own
host key.  There's a rarely-used (and quite insecure) authentication
scheme called "[host-based user authentication][hba]" that uses a host
key from the client and then trusts any information the client gives
it about which user is trying to connect. Do not ever use this, and
don't confuse the client's host key with the server's host key.

#### Client User Key

This is the usual method of the client authenticating itself to the
server; the key typically belongs to a "user" rather than a host. The
server will have one or more public keys in the `.ssh/authorized_keys`
file under the user's home directory and will request that the client
prove who it is by proving it has the private key part of that
keypair.


References
----------

* SSH Communications Security, [Cryptography for Practitioners][SSH-crypto]
* Wikipedia, [Public Key Infrastructure][PKI]
* Wikipedia, [SSH Architecture]
* [RFC 4251: The Secure Shell (SSH) Protocol Architecture][RFC 4251]
* [`sshd` manpage][sshd]
* [`ssh_config` manpage][ssh_config]
* OpenSSH Cookbook, [Host-based User Authentication][hba]

[SSH-crypto]: https://www.ssh.com/cryptography/
[PKI]: https://en.wikipedia.org/wiki/Public_key_infrastructure
[SSH Architecture]: https://en.wikipedia.org/wiki/Secure_Shell#Architecture
[RFC 4251]: https://tools.ietf.org/html/rfc4251
[README.md]: README.md
[Example.rb]: Example.rb
[sshd]: https://www.freebsd.org/cgi/man.cgi?query=sshd#SSH_KNOWN_HOSTS_FILE_FORMAT
[ssh_config]: https://www.freebsd.org/cgi/man.cgi?query=ssh_config
[hba]: https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Host-based_Authentication
