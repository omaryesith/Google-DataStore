package Google::DataStore::CommitRequest;
use 5.010001;
use strict;
use warnings;


sub new {
  my ($class, %args) = @_;
  my $self = bless { %args }, $class;
  return $self;
}

sub transaction {
  my ($self, $transaction) = @_;
  $self->{request}{transaction} = $transaction // return;
}

sub AddMutation {
	my ($self, %args) = @_;

	die "undefined mutation to set" if !defined $args{mutation};

	$self->{mutation} = $args{mutation};
	$self->{request}{mutation}{$self->{mutation}} = [];
	$self->{request}{mutation}{$self->{mutation}}[0]{key} = $args{key} if defined $args{key};	
	$self->{request}{mutation}{$self->{mutation}}[0]{properties} = {};
}

sub AddKey {
	my ($self, $key) = @_;

	die "undefined key to attach" if !defined $key;

	$self->{request}{mutation}{$self->{mutation}}[0]{key} = $key;
}

sub AddProperty {
	my ($self, %args) = @_;

	die "undefined property name" if !defined $args{name};
	die "undefined property type" if !defined $args{type};
	die "undefined property value" if !defined $args{value};
	
	$self->{request}{mutation}{$self->{mutation}}[0]{properties}{$args{name}}{$args{type}} = $args{value};
}
1;