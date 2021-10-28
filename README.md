# Arch Install Wrapper

My personal Arch Linux install script.  It takes an opinionated approach to installing Arch with
some level of customisation available via a config file.

This is an update to my old singular file script which can still be found in `old-script`.  I took
inspiration from Chris Titus' [ArchTitus](https://github.com/ChrisTitusTech/ArchTitus) project
to separate the different 'stages' of installation into their own respective scripts to keep it
more maintainable.

In addition, this set of scripts differs by means of getting away from CLI arguments to using a
configuration file instead, so I can save my exact configuration and take it wherever I want.

Finally, the scope has increased beyond a barebones Arch install with nothing else, to configuring
a desktop environment to my liking.  This will be achieved by means of [Konsave](https://github.com/Prayag2/konsave),
so it would be possible to drop in any saved configuration you like.

## Base System

So what is the base setup with no customisation?

## Customisation

Customisation is done vie editing the `customisation.conf` file.  Below are the supported values