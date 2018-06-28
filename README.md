[![Build Status](https://travis-ci.org/lizmat/Object-Trampoline.svg?branch=master)](https://travis-ci.org/lizmat/Object-Trampoline)

NAME
====

Object::Trampoline - Port of Perl 5's Object::Trampoline 1.50.4

SYNOPSIS
========

    # direct object creation
    my $dbh = DBIish.connect( ... );
    my $sth = $dbh.prepare( 'select foo from bar');

    if $need-to-execute {
        $sth.execute; # execute
    }
    else {
        say "database handle and statement executed without need";
    }

    # with delayed object creation
    use Object::Trampoline;
     
    my $dbh = Object::Trampoline.connect( DBIish, ... );
    my $sth = Object::Trampoline.prepare( $dbh, 'select foo from bar');

    if $need-to-execute {
        $sth.execute; # create $dbh, then $sth, then execute
    }
    else {
        say "no database handle opened or statement executed";
    }

DESCRIPTION
===========

There are times when constructing an object is expensive but you are not sure yet you are going to need it. In that case it can be handy to delay the creation of the object. But then your code may become much more complicated.

This module allows you to transparently create an intermediate object that will perform the delayed creation of the original object when **any** method is called on it.

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/Object-Trampoline . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Re-imagined from the Perl 5 version as part of the CPAN Butterfly Plan. Perl 5 version originally developed by Steven Lembark.

