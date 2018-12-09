use v6.c;

use InterceptAllMethods;

class Object::Trampoline:ver<0.0.6>:auth<cpan:ELIZABETH> {
    has Mu   $!code;  # code to get object, if that still needs to be done
    has Lock $!lock;  # lock to make sure only one thread gets to create object
    has Mu $!result;  # result of final method call (in case multi-threaded)

    # ALL method calls will call this method, which will return a Method
    # object of the method that will actually be called.
    method ^find_method(Mu \type, Str:D $name) {
        my constant &proto-handler = proto method handler(|) {*}

        # Set up instantiated Object::Trampoline object that contains the
        # original object, the name of the method to call, and any arguments.
        multi method handler(Object::Trampoline:U: \object, |args) {
            trampoline( { object."$name"(|args) } )
        }

        # Take the instantiated Object::Trampoline object, call the originally
        # intended method on the original object and store that as the new
        # object.  Then call the given method and arguments on that object and
        # return its result.  Make sure only on thread gets to do this at any
        # time.
        multi method handler(Object::Trampoline:D \SELF: |args) is raw {

            # special case for "if" and "with" constructs
            if $name eq 'defined' || $name eq 'Bool' {
                False
            }

            # do the real thing
            else {
                $!lock.protect: {
                    if $!code {
                        my $object := $!code();  # run code to create object

                        # Alas, we need to revert to nqp to prevent method
                        # .STORE being called on the object, which would send
                        # this off into an infiniloop.
                        use nqp;
                        nqp::assign(SELF,$object) if nqp::iscont(SELF);

                        $!result := $object."$name"(|args);  # create result
                        $!code := Mu;                        # run code once
                    }
                    $!result
                }
            }
        }

        # Return the proto of the handler
        &proto-handler
    }
}

my sub trampoline(&code) is export {

    # Alas, we need to revert to nqp methods to be able to create the
    # Object::Trampoline object, as all normal logic is inaccessible due
    # to the catching of *all* methods.
    use nqp;
    nqp::p6bindattrinvres(
      nqp::p6bindattrinvres(
        nqp::create(Object::Trampoline),
        Object::Trampoline,
        '$!code',
        &code
      ),
      Object::Trampoline,
      '$!lock',
      Lock.new
    )
}

=begin pod

=head1 NAME

Object::Trampoline - Port of Perl 5's Object::Trampoline 1.50.4

=head1 SYNOPSIS

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

=head1 DESCRIPTION

There are times when constructing an object is expensive but you are not sure
yet you are going to need it.  In that case it can be handy to delay the
creation of the object.  But then your code may become much more complicated.

This module allows you to transparently create an intermediate object that
will perform the delayed creation of the original object when B<any> method
is called on it.

The original Perl 5 was is to call B<any> method on the C<Object::Trampoline>
class, with as the first parameter the object to call that method on when
it needs to be created, and the other parameters the parameters to give to
that method then.

The alternate, more idiomatic Perl 6 way, is to call the C<trampoline>
subroutine with a code block that contains the code to be executed to create
the final object.  This can also be used to serve as a lazy default value
for a class attribute.

To make it easier to check whether the actual object has been created, you
can check for C<.defined> or booleaness of the object without actually
creating the object.  This can e.g. be used when wanting to disconnect a
database handle upon exiting a scope, but only if an actual connection has
been made (to prevent it from making the connection only to be able to
disconnect it).

=head1 PORTING CAVEATS

Due to the lexical scope of C<use> in Perl 6, it is not really possible to
mimic the behaviour of C<Object::Trampoline::Use>.

Due to the nature of the implementation, it is not possible to use smartmatch
(aka C<~~>) on a trampolined object.  This is because smartmatching a
trampolined object does not call any methods on it.  Fixing that by using a
C<Proxy> would break the C<.defined> and C<.Bool> functionality.

You can also not call C<.WHAT> on a trampolined object.  This is because
C<.WHAT> is internally generated as a call to C<nqp::what>, and it is as yet
impossible to provide candidates for nqp:: ops.

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
