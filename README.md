[![Build Status](https://travis-ci.org/lizmat/Object-Trampoline.svg?branch=master)](https://travis-ci.org/lizmat/Object-Trampoline)

NAME
====

Object::Trampoline - Port of Perl 5's Object::Trampoline 1.50.4

SYNOPSIS
========

    # direct object creation
    my $dbh = DBIish.connect( ... );
    my $sth = $dbh.prepare( 'select foo from bar' );

    if $need-to-execute {
        $sth.execute; # execute
    }
    else {
        say "database handle and statement executed without need";
    }

    # with delayed object creation
    use Object::Trampoline;
     
    my $dbh = Object::Trampoline.connect( DBIish, ... );
    my $sth = Object::Trampoline.prepare( $dbh, 'select foo from bar' );

    if $need-to-execute {
        $sth.execute; # create $dbh, then $sth, then execute
    }
    else {
        say "no database handle opened or statement executed";
    }
    LEAVE .disconnect with $dbh;  # only disconnects if connection was made

    # alternate setup way, more idiomatic Perl6
    my $dbh = trampoline { DBIish.connect: ... }
    my $sth = trampoline { $dbh.prepare: 'select foo from bar' }

    # lazy default values for attributes in objects
    class Foo {
        has $.bar = trampoline { say "delayed init"; "bar" }
    }
    my $foo = Foo.new;
    say $foo.bar;  # delayed init; bar

DESCRIPTION
===========

There are times when constructing an object is expensive but you are not sure yet you are going to need it. In that case it can be handy to delay the creation of the object. But then your code may become much more complicated.

This module allows you to transparently create an intermediate object that will perform the delayed creation of the original object when **any** method is called on it.

The original Perl 5 was is to call **any** method on the `Object::Trampoline` class, with as the first parameter the object to call that method on when it needs to be created, and the other parameters the parameters to give to that method then.

The alternate, more idiomatic Perl 6 way, is to call the `trampoline` subroutine with a code block that contains the code to be executed to create the final object. This can also be used to serve as a lazy default value for a class attribute.

To make it easier to check whether the actual object has been created, you can check for `.defined` or booleaness of the object without actually creating the object. This can e.g. be used when wanting to disconnect a database handle upon exiting a scope, but only if an actual connection has been made (to prevent it from making the connection only to be able to disconnect it).

PORTING CAVEATS
===============

Due to the lexical scope of `use` in Perl 6, it is not really possible to mimic the behaviour of `Object::Trampoline::Use`.

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/Object-Trampoline . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Re-imagined from the Perl 5 version as part of the CPAN Butterfly Plan. Perl 5 version originally developed by Steven Lembark.

