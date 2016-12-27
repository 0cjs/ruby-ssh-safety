Can Client Authentication Stop MITM?
====================================

Preface
-------

While this dicussion is very interesting for those with an intense
desire to analyse cryptosystems in detail, I expect that most people
don't want to be carefully considering all the implications of this
analysis for every SSH connection they use in their day-to-day work.
Thus, I strongly encourage you to take the easy way out, which is
simply always to properly authenticate the SSH servers to which you
connect.


Introduction
------------

[@fred] raised a question in [Issue #1]:

> Regarding this info in the readme:
>
> > He can now proxy your connection on to the real host, reading and
> > modifying all your data at will.
>
> I think it’s not possible since the attacker does not have your
> private SSH key, thus not able to authenticate with the final
> destination server on your behalf.

After I indicated correctly that the client authentication is not done
by the attacker or, often, not even by the SSH client, further
(private) discussion led to a discussion about whether or not the
client would be unable to authenticate to the real server due to the
attacker being an MITM.

When discussing this, there are two cases we need to consider:

1. The attacker can somehow let the client authenticate to the real
   server, in which case it's game over: it has access to see and
   modify all data passing across the connection (even if it cannot
   later re-use that authentication in a different connection).

2. The real server is not able to authenticate the client, but the
   attacker can forge an authentication request to the client for
   which it will accept the response, leading the client to believe
   that it's authenticated to the real server when actually it is not.

We'll deal with the second case first, which serves as a proof that
even if 1. is false, 2. still gives useful privileges to the attacker.

[@fred]: https://github.com/fred
[Issue #1]: https://github.com/c-j-s/ruby-ssh-safety/issues/1


Authentication to Attacker
--------------------------

Let's assume that the client (incorrectly) authenticated the attacker
as the real server....

XXX

If the client is merely sending one or more files via SFTP, the
attacker need not contact the real server at all but merely approve
any authentication requests and accept the files. "All your data are
belong to us."

This may be a solution to propose to the poster of
https://www.reddit.com/r/HowToHack/comments/4zsypi/ssh_mitm_what_are_my_options/


Authentication to Real Server
-----------------------------

XXX

Need to fill in, but looks like it can't happen with PK auth when
you're guaranteed your transport is standard SSH transport protocol?

So what are other avenues of attack? How about using agent forwarding
(if enabled) to let the MITM proxy over the auth request. Are those
authentication requests also signing a session hash? If so, which one?


Authentication to Faked Real Server
-----------------------------------

In the case of leaked or guessable server keys, there exists
some attack code already:

  https://github.com/wertarbyte/mallory-in-the-middle

This is particularly clever in that the MITM server/client can go
passive when it can't successfully attack, thus hiding its presence
until things change such that it can make the attack.


Discussion of PK Auth Preventing These Attacks (Sometimes)
----------------------------------------------------------

* http://www.gremwell.com/ssh-mitm-public-key-authentication
  (Source of how this will at least in some circumstances prevent an attack.)

* https://security.stackexchange.com/questions/67242/does-public-key-auth-in-ssh-prevent-most-mitm-attacks
  (Lots of things to comment on/fix in the answers to this one)
