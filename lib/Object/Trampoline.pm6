use v6.c;

use InterceptAllMethods;

class Object::Trampoline:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has $!object;
    has $!name;
    has $!args;

    # ALL method calls will call this method, which will return a Method
    # object of the method that will actually be called.
    method ^find_method(Mu \type, Str:D $name) {
        my constant &proto-handler = proto method handler(|) {*}

        # Set up instantiated Object::Trampoline object that contains the
        # original object, the name of the method to call, and any arguments.
        multi method handler(Object::Trampoline:U: \object, |args) {

            # Alas, since *all* methods are caught here, there is no easy
            # way to set attributes in the objects of this class.  So we
            # resort to using NQP here.
            use nqp;
            my \trampoline = nqp::create(Object::Trampoline);
            nqp::bindattr(trampoline,Object::Trampoline,'$!object',  object);
            nqp::bindattr(trampoline,Object::Trampoline,  '$!name', $name  );
            nqp::bindattr(trampoline,Object::Trampoline,  '$!args',  args  );
            trampoline
        }

        # Take the instantiated Object::Trampoline object, call the originally
        # intended method on the original object and store that as the new
        # object.  Then call the given method and arguments on that object and
        # return its result.
        multi method handler(Object::Trampoline:D \SELF: |args) {
            (SELF = $!object."$!name"(|$!args))."$name"(|args)
        }

        # Return the proto of the handler
        &proto-handler
    }
}

=begin pod

=head1 NAME

Object::Trampoline - Port of Perl 5's Object::Trampoline 1.50.4

=head1 SYNOPSIS

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

=head1 DESCRIPTION

There are times when constructing an object is expensive but you are not sure
yet you are going to need it.  In that case it can be handy to delay the
creation of the object.  But then your code may become much more complicated.

This module allows you to transparently create an intermediate object that
will perform the delayed creation of the original object when B<any> method
is called on it.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/Object-Trampoline .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Re-imagined from the Perl 5 version as part of the CPAN Butterfly Plan. Perl 5
version originally developed by Steven Lembark.

=end pod
