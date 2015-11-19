package Google::DataStore::Key;
use 5.010001;
use strict;
use warnings;


sub new {
  my ($class, %args) = @_;
  my $self = bless { %args }, $class;

  $self->{key}{partitionId}{datasetId} = $args{datasetId} if defined $args{datasetId};
  $self->{key}{partitionId}{namespace} = $args{namespace} if defined $args{namespace};

  return $self;
}

sub DESTROY {
}

sub AddPathElement {
  my ($self, %args) = @_;
  my @path = {};
  push @{$self->{key}{path}}, @path;

  $self->{key}{path}[scalar(@{$self->{key}{path}})-1]{kind} = $args{kind} if defined $args{kind};
  $self->{key}{path}[scalar(@{$self->{key}{path}})-1]{name} = $args{name} if defined $args{name};
  $self->{key}{path}[scalar(@{$self->{key}{path}})-1]{id} = $args{id} if defined $args{id};

  return $self->{key}{path}[scalar(@{$self->{key}{path}})-1];
}
1;
