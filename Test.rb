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
hostkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=='
wronghostkey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1VJn8gp5A8FZRpemLgUePg/qlsJWqZYxVMtjOvziCh/vKXoCuddWo8Ehsxm++1fwMIf0BIZXQpH1EymH8joMOImfDm8UQ5OsTnP5T5+9NF7dH6BveK8VIZTJcRGX80CzfpEESmC0I3fbB1JoMVwEvznQnSveIcfvyhhoGUIO1L3L06s2LBRQRuGpM3razYW0W0z9qXegEivxQpvjG5OLAkaoVtdZ5zMlkGbKf+IWXL9S0pCZWrtOBLG42m5UF5V3vTfi2+Fiq8pMhGlMcpsgJ3bzuf93m+v7Z+bGbsI+Qq2qsT8cm7j8YH9TaUq9A737yPQeSuGpTovq5c6rqmo/D'

puts("You should see no exceptions.")

# Now we connect and we should fail because we can't verify the key of
# the host to which we're connecting (or any host, for that matter).
#
begin
    puts("\nConnecting to #{host} with no known hosts...")
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

############################################################

# So now we need to specify the key we know, and assert we can
# connect.
#
# You'd think you could set the `:host_key` configuration parameter,
# right? Nope, because that's not the host key. That's the host key
# algorithm.
#
# Instead we need to pass in our known host keys via the
# `:known_hosts` parameter. This must be an object similar to
# `KnownHosts` (`lib/net/ssh/known_hosts.rb`) in that it responds to a
# `search_for(host, options={})` method. (This is not entirely clearly
# a public interface, but looks intended to be so.)
#
# Let's do it in a way slightly more generic than really needed, so
# that people can steal the class.
#
class MyKnownHost < Array

    # This should, in theory, return a `Net::SSH::HostKeys` object, or
    # at least something that responds to both some unspecified
    # `Array` methods (acting as a list of host keys), `host` and
    # `add_host_key`.
    #
    # Since we run in "sensible" mode (sometimes derogatively referred
    # to as "ultra-paranoid" mode by those who harbour a secret desire
    # to be 0wnd) we would never "add" a key because that by
    # definition is someone we don't know and, and we only want to
    # connect to those we know. So we do respond to `add_host_key`,
    # but only with a raspberry.
    #
    def search_for(host, options = {})
        h = host.split(',')[0]
        h == @host ? self
                   : raise("Wrong host: #{h.inspect} (from #{host.inspect})")
    end

    attr_reader :host

    def initialize(host, pubkeys)
        @host = host
        super(pubkeys.map { |keyline|
            type, key = keyline.split(' ', 2)
            # XXX we just assume it's a supported type, yeah, that's lazybad
            blob = key.unpack('m*').first
            Net::SSH::Buffer.new(blob).read_key
        })
    end

    def add_host_key(key)
        fail("BZZZT! You should not be trying to add a key for host #{host}")
    end

end

config[:known_hosts] = MyKnownHost.new(host, [wronghostkey])
puts("\nConnecting to known host #{host} with bad host key...")
begin
    Net::SSH.start(host, 'git', config) {
        |s| fail("Connection should have failed") }
rescue Net::SSH::HostKeyMismatch => e
    puts("Correctly received HostKeyMismatch.")
rescue => e
    fail("ERROR: should not have gotten exception #{e.class}:\n  #{e}")
end

# XXX We should test that with less paranoid options our
# `MyKnownHost::add_host_key` properly gives you 'ttthhhhbbbbt!'

config[:known_hosts] = MyKnownHost.new(host, [hostkey])
puts("\nConnecting to known host #{host} with good host key...")
Net::SSH.start(host, 'git', config) {
    |session| puts("Correctly connected to #{session.host}") }

# If we needed to authenticate ourselves, once we've determined a host
# is ok, we'd need to add our authentication material to the config.

# If we're connecting to a server hungry to be 0wned, use a password.
#
config[:password] = 'Own me because this is weak.'

# But if we're sensible, we use a key.
# XXX Figure out how to do this in a better way than reading a file.
#
config[:keys] = "/path/to/ssh/key"
