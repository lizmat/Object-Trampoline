use v6.c;

use InterceptAllMethods;

class Object::Trampoline:ver<0.0.2>:auth<cpan:ELIZABETH> {
    has &!code;    # code to get object, if that still needs to be done
    has $!lock;    # lock to make sure only one thread gets to create object
    has $!result;  # result of final method call (in case multi-threaded)

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
            $!lock.protect: {
                if &!code {
                    $!result := (SELF = &!code())."$name"(|args);
                    &!code := Callable;
                }
                $!result
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
        '&!code',
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

    # alternate setup way, more idiomatic Perl6
    my $dbh = trampoline { DBIish.connect: ... }
    my $sth = trampoline { $dbh.prepare: 'select foo from bar' }

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
the final object.

=head1 PORTING CAVEATS

Due to the lexical scope of C<use> in Perl 6, it is not really possible to
mimic the behaviour of C<Object::Trampoline::Use>.

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
