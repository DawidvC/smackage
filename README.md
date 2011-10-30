Smackage is a prototype package manager for Standard ML libraries. Right now 
it does not do any installation, it just provides a standard way of getting
Standard ML code that understands where other Standard ML code might be found
on the filesystem.

Installation
============
Installation takes three steps, and the first is optional.

1. First, you have to pick the `$SMACKAGE_HOME` files where Smackage will put
   all of its files. This will be `~/.smackage` by default if you don't do
   anything; see the section "The $SMACKAGE_HOME directory" below if you'd like
   Smackage to put its files somewhere else.
2. Second, you have to configure your SML compilers to find the code that
   Smackage will put on your system; see the section "Setting up your SML path
   map" below.
3. Finally you can actually build Smackage with the following commands:

    $ cd smackage
    $ make mlton # (or make smlnj)
    $ bin/smackage refresh
    $ bin/smackage get cmlib

Referring to Smackage packages
------------------------------
If you've performed all the steps described above, you can will be able to 
refer to cmlib as `$SMACKAGE/cmlib/v0/cmlib.cm` (in SML/NJ .cm files) or as 
`$(SMACKAGE)/cmlib/v0/cmlib.mlb` (in MLton .mlb files).

You might want to add `$SMACKAGE_HOME/bin` to your path if you want to use 
applications compiled through smackage.

Building Smackage with Smackage
-------------------------------
Smackage doesn't have a uniform build process, at least not yet. Instead, we
support a simple `smackage make` command. If you type 
`smackage make package blah blah blah`, smackage will try to run 
`make blah blah blah` in the directory where `package` lives.

Therefore, if you're on a reasonably Unix-ey system (OSX or Linux), the 
following the following commands will install smackage into the directory
`$SMACKAGE_HOME/bin`.

    $ bin/smackage refresh
    $ bin/smackage make smackage mlton # or smlnj
    $ bin/smackage make smackage smackage-install

If you have a Windows+Cygwin setup (smackage only works within Cygwin on
Windows), then you can try replacing the second command with 

    $ bin/smackage make smackage win+smlnj

but your mileage may vary.

Setting up your SML path map
============================
Smackage will live in a directory that we'll refer to
as `$SMACKAGE_HOME` in this section. This directory is probably 
`~/.smackage`, but see the section on `$SMACKAGE_HOME` below for more 
information. Whenever you see the string `$SMACKAGE_HOME` in this system, you 
should replace it with the appropriate absolute file path, for instance I 
wouldn't actually write

    SMACKAGE $SMACKAGE_HOME/lib

in a pathconfig file for Standard ML of New Jersey; instead, I'd write 

    SMACKAGE /Users/rjsimmon/.smackage/lib

Make sure you use an absolute path - starting with "/", or whatever your system
uses to refer to the file system root.

Setting up SML/NJ (system-wide)
-------------------------------
Find the file `lib/pathconfig` in the installation directory for SML/NJ, and 
add the following line:
  
    SMACKAGE $SMACKAGE_HOME/lib

Setting up SML/NJ (user-only)
-----------------------------
Create a file `~/.smlnj-pathconfig` containing the following line (or add
the following line to `~/.smlnj-pathconfig` if it exists already):

    SMACKAGE $SMACKAGE_HOME/lib

Setting up MLton (system-wide)
------------------------------
Find the [MLBasis Path Map](http://mlton.org/MLBasisPathMap), stored
in a file called `mlb-path-map`, usually somewhere like 
`/usr/lib/mlton/mlb-path-map` or 
`/usr/local/lib/mlton/mlb-path-map`, depending on your system. Add the line

    SMACKAGE $SMACKAGE_HOME/lib

Setting up MLton (user-only)
------------------------
MLton doesn't currently allow user-specific basis maps like SML/NJ does,
but there is a workaround if you put the following shell script, called, 
`mlton` on your search path so that your operating system will find it before 
it finds the regular MLton binary:

    XXX sully how did you do this?

The $SMACKAGE_HOME directory
============================
Smackage has to figure out where it lives on the file system whenever it
starts up; the installation instructions referred to the directory where
smackage lives as `$SMACKAGE_HOME`. Smackage goes through the following process
to try and determine `$SMACKAGE_HOME`:

 1. If the `SMACKAGE_HOME` environment variable is defined, then smackage will
    always use that as `$SMACKAGE_HOME`. If this directory does not 
    exist, smackage will try to create it. Otherwise,
 2. If `/usr/local/smackage` exists, smackage will use that as
    `$SMACKAGE_HOME`. Otherwise,
 3. If `/opt/smackage/` exists, smackage will use that as
    `$SMACKAGE_HOME`. Otherwise,
 4. As a last resort, smackage will try to use `~/.smackage`, where `~` is 
    defined by the `HOME` environment variable. If this directory does not 
    exist, smackage will try to create it. 

