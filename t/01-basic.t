use v6.*;
use Test;
use Object::Trampoline;

plan 18;

my @seen;

class Bar {
    has $.zop;
    submethod TWEAK() { @seen.push("Bar") }
}

class Foo {
    has $.zip = 42;
    submethod TWEAK() { @seen.push("Foo") }
    method Bar() { Bar.new( zop => $.zip ) }
}

# simple trampoline
my $foo = Object::Trampoline.new: Foo;
use nqp;
ok nqp::eqaddr($foo.WHAT,Object::Trampoline),
  'did we get an Object::Trampoline';
nok $foo.defined, 'is $foo marked as undefined';
nok ?$foo, 'is $foo marked as False';

is +@seen, 0, 'no Foo object created yet';

is $foo.zip, 42, 'did we get the right bar';
isa-ok $foo, Foo, 'do we have a Foo object now';
is @seen, "Foo", 'did we create an object now';

# another simple trampoline
$foo = Object::Trampoline.new: Foo, zip => 666;
ok nqp::eqaddr($foo.WHAT,Object::Trampoline),
  'did we get an Object::Trampoline again';
is $foo.zip, 666, 'did we get the right bar again';
isa-ok $foo, Foo, 'do we have a Foo object again';
is @seen, "Foo Foo", 'did we create an object again';

# stacked trampolines
   $foo = Object::Trampoline.new: Foo, zip => 314;
my $bar = Object::Trampoline.Bar: $foo;
ok nqp::eqaddr($foo.WHAT,Object::Trampoline),
  'did we get an Object::Trampoline yet again';
ok nqp::eqaddr($bar.WHAT,Object::Trampoline),
  'did we get an Object::Trampoline yet again';
is @seen, "Foo Foo", 'did we not create any real object again';

is $bar.zop, 314, 'did we get the right object and value';
isa-ok $foo, Foo, 'do we have a Foo object again';
isa-ok $bar, Bar, 'do we have a Bar object';
is @seen, "Foo Foo Foo Bar", 'did we not create any real object again';

# vim: expandtab shiftwidth=4
