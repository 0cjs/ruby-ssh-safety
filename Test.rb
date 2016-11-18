#!/usr/bin/env ruby

require 'net/ssh'

# OpenSSH has configuration files such as `~/.ssh/config` that can set
# connection parameters (e.g., does it forward an SSH agent
# connection?) for particular "hostnames" given on the command line.
#
# Net:SSH stores similar information for a potential connection
# in the Net::SSH::Configuration class (documented at
# http://net-ssh.github.io/net-ssh/Net/SSH/Config.html), and this
# can be loaded via `Net::SSH.configuration_for()`. If the second
# parmaeter (`use_ssh_config`) is set to its default of `true`,
# Net::SSH will attempt to read and parse the user's OpenSSH
# configuration files for settings for the host.
#
config = Net::SSH.configuration_for('127.0.0.1', true)
    p(config)

# Probably your configuration for `127.0.0.1` will include #
# `'password'` in the `:auth_methods` array. We don't want that
# because like all good testers we want to promote failure, even if
# you're so silly as to have enabled password auth in
# `/etc/ssh/sshd_config`. So let's remove it.
#
config[:auth_methods].delete('password')
    p(config)

# OpenSSH builds, in `~/.ssh/known_hosts`, a read/write database of the
# public keys of hosts to which it connects. This would be somewhat
# effective in preventing MITM attacks if only people didn't just
# automatically type "yes" whenever SSH prompted them. Anyway, it seems
# that Net::SSH uses a similar file, since the above config includes
# something like
#    :user_known_hosts_file => "~/.ssh/known_hosts"

    p(config[:user_known_hosts_file])

# But we don't need to write, since we should get our key information
# out of band. So how do we set up something where we don't need an
# external file, but we can do in our production config, "here's the
# key we need to assert they have," or we alert?


exit(1) # FIXUP stuff below this

host            = '127.0.0.1'
port            = 222
login_name      = 'l0s3r'
password        = nil
ssh_key_path    = nil


#Net::SSH.start(host, login_name, password: password, keys: [ssh_key_path])
Net::SSH.start(host, login_name) {
    |s|     # `Connection::Session`, which has `Connection:Channel`s
    p("Ok, we connected!")
    p(s)
}
