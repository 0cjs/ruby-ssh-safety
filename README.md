Demonstrate and Play with Ruby's Net::SSH
=========================================

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
