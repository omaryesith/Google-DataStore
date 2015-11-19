package Google::DataStore::Entity;
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
