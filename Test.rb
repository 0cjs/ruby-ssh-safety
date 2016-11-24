#!/usr/bin/env ruby

# WARNING! Everything described in this file was checked against
# Net::SSH v3.2.0, https://github.com/net-ssh/net-ssh/tree/v3.2.0
# (commit e279c5e). Other versions may be apropriately different.
# Some of the things here appear to dig into the Net::SSH internals a
# little more than may be comfortable for some.
#
require 'net/ssh'

# OpenSSH has configuration files such as `~/.ssh/config` that can set
# connection parameters (e.g., does it forward an SSH agent
# connection?) for particular "hostnames" given on the command line.
#
# Net:SSH stores similar information for a potential connection
# in the Net::SSH::Configuration class (documented at
# http://net-ssh.github.io/net-ssh/Net/SSH/Config.html), and this
# can be loaded via `Net::SSH.configuration_for()`. If the second
# parameter (`use_ssh_config`) is set to its default of `true`,
# Net::SSH will attempt to read and parse the user's OpenSSH
# configuration files for settings for the host.
#
config = Net::SSH.configuration_for('127.0.0.1', true)

# Probably your configuration for `127.0.0.1` will include #
# `'password'` in the `:auth_methods` array. We don't want that
# because like all good testers we want to promote failure, even if
# you're so silly as to have enabled password auth in
# `/etc/ssh/sshd_config`. So let's remove it.
#
config[:auth_methods].delete('password')

# OpenSSH builds, in `~/.ssh/known_hosts`, a read/write database of
# the public keys of hosts to which it connects. This would be
# somewhat effective in preventing MITM attacks if only people didn't
# just automatically type "yes" whenever SSH prompted them to add to
# it the key for any not-yet-known host. (The message unfortunately
# does not read, "The host to which you've connected may be an
# attacker trying to read and modify all your data. Do you want to
# give this attacker control of all your data? (Y/N)".)
#
# Net::SSH reads files in the same format using the `KnownHosts` class
# (`lib/net/ssh/known_hosts.rb`). The filenames are given as a
# `String` or array of `String` in the `:global_known_hosts_file` and
# `:user_known_hosts_file` parameters. New keys that are accepted
# (Accepted how? See below.) will be written to the first file in
# `:user_known_hosts_file` that it can write (see `KnownHosts::add`).

# To make life easy, the first thing we want to do is make sure we
# don't use any of these files so that we don't have to worry about
# whether on the current host on which we happen to be deployed they
# do or do not have good contents. We can't set these to `nil` because
# then the defaults will be used (see `KnownHosts::hostfiles`), so we
# use `/dev/null`. XXX Unfortunately this allows writes (though the
# data will be lost), which might mask some errors.
#
config[:global_known_hosts_file] = '/dev/null'
config[:user_known_hosts_file]   = '/dev/null'

# But this isn't enough! We know that there are no existing keys
# available from the known_hosts files, but what decides whether a new
# key is accepted? This would be the "verifier," usually a class from
# the `Net::SSH::Verifiers` module. There are various ones that
# automatically accept keys in various circumstances (including being
# dependent on the particular IP address and port whence you're
# connecting), or we could provide our own class that responds to
# `verify` (see `Sesion.select_host_key_verifier` in
# `lib/net/ssh/transport/session.rb`). Confusingly enough, the
# `Strict` verifier (`lib/net/ssh/verifiers/strict.rb`) does what the
# SSH configuration option `StrictHostKeyChecking NO` does: that is,
# automatically accepts any key for a host it's not seen before.
#
# The easy thing to do here, as in so many security situations is not
# to analyze the complexity of this but just to remove it. Setting the
# `:paranoid` setting in the config to `:secure` should make it reject
# any connection for which we don't already know a key, as well as any
# where the key doesn't match.
#
config[:paranoid] = :secure

############################################################

# For our testing, github.com conveniently offers an SSH server
# with a key that we know.
#
host = 'github.com'

# Now we connect and we should fail because we can't verify the key of
# the host to which we're connecting (or any host, for that matter).
#
begin
    puts("\nConnecting to #{host}...")
    Net::SSH.start(host, 'user', config)
    fail("ERROR: Should not have successfully authenticated!")
rescue Net::SSH::HostKeyUnknown => e
    puts("Correctly received HostKeyUnknown.")
    #puts("  #{e}")
rescue Net::SSH::AuthenticationFailed => e
    fail("ERROR: Should not have successfully connected!")
rescue => e
    fail("ERROR: should not have gotten exception #{e.class}:\n  #{e}")
end

# And this is sorta what we might use in a more serious situation.
#Net::SSH.start(host, login_name, password: password, keys: [ssh_key_path])
