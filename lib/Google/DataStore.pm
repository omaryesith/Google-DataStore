package Google::DataStore;
use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01';

use Class::Load qw(load_class);
use Crypt::OpenSSL::PKCS12;
use JSON qw(decode_json encode_json);
use JSON::WebToken;
use LWP::UserAgent;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Google::DataStore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

sub create {
  my (%args) = @_;

  my $version = $args{version} // 'v1beta2';
  my $class = 'Google::DataStore::' . ucfirst($version);

  if (load_class($class)) {
    return $class->new(%args);
  } else {
    die "Can't load class: $class";
  }
}

sub new {
  my ($class, %args) = @_;

  die "undefined client_email" if !defined $args{client_email};
  die "undefined private_key_file" if !defined $args{private_key_file};
  die "not found private_key_file" if !-f $args{private_key_file};

  my $self = bless { %args }, $class;

  $self->{GOOGLE_API_TOKEN_URI} = 'https://accounts.google.com/o/oauth2/token';
  $self->{GOOGLE_API_GRANT_TYPE} = 'urn:ietf:params:oauth:grant-type:jwt-bearer';

  if ($self->{private_key_file} =~ /\.json$/) {
    open my $in, "<", $self->{private_key_file} or die "can't open $self->{private_key_file} : $!";
    my $private_key_json = decode_json(join('', <$in>));
    close $in;
    $self->{private_key} = $private_key_json->{private_key};
  } elsif ($self->{private_key_file} =~ /\.p12$/) {
    my $password = "notasecret";
    my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file($self->{private_key_file});
    $self->{private_key} = $pkcs12->private_key($password);
  } else {
    die "invalid private_key_file format";
  }

  $self->_auth;
  $self->_set_rest_description;

  return $self;
}

sub DESTROY {
}

sub _auth {
  my ($self) = @_;

  $self->{scope} //= [qw(https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/datastore)];
  $self->{exp} = time + 3600;
  $self->{iat} = time;
  $self->{ua} = LWP::UserAgent->new;

  my $claim = {
    iss => $self->{client_email},
    scope => join(" ", @{$self->{scope}}),
    aud => $self->{GOOGLE_API_TOKEN_URI},
    exp => $self->{exp},
    iat => $self->{iat},
  };

  my $jwt = JSON::WebToken::encode_jwt($claim, $self->{private_key}, 'RS256', { type => 'JWT' });

  my $response = $self->{ua}->post(
    $self->{GOOGLE_API_TOKEN_URI},
    { grant_type => $self->{GOOGLE_API_GRANT_TYPE}, assertion => $jwt }
  );
  
if ($response->is_success) {
    $self->{access_token} = decode_json($response->decoded_content);
  } else {
    my $error = decode_json($response->decoded_content);
    die $error->{error};
  }
}

sub _set_rest_description {
  my ($self) = @_;
  my $response = $self->{ua}->get($self->{GOOGLE_DATASTORE_REST_DESCRIPTION});
  use Data::Dumper;
  print Dumper($response);
  $self->{rest_description} = decode_json($response->decoded_content);
}

sub use_project {
  my ($self, $project_id) = @_;
  $self->{project_id} = $project_id // return;
}

sub use_dataset {
  my ($self, $dataset_id) = @_;
  $self->{dataset_id} = $dataset_id // return;
}

sub use_namespace {
  my ($self, $namespace) = @_;
  $self->{namespace} = $namespace // return;
}

sub allocateIds {

}

sub beginTransaction {
  my ($self, %args) = @_;

  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $project_id = $args{project_id} // $self->{project_id};

  my $isolationLevel = (defined $args{isolationLevel}) ? $args{isolationLevel} : 'SNAPSHOT';
  my $content->{isolationLevel} = $isolationLevel;

  my $response = $self->request(
    resource => 'datasets',
    method => 'beginTransaction',
    project_id => $project_id,
    dataset_id => $dataset_id,
    content => $content,
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return $response->{error}{message};
  } else {
    return $response->{transaction};
  }
}

sub CommitRequest {
  my ($self, %args) = @_;
  my $class = 'Google::DataStore::CommitRequest';
  
  if (load_class($class)) {
    return $class->new();
  } else {
    die "Can't load class: $class";
  } 
}

sub commit {
  my ($self, $content, %args) = @_;

  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  my $response = $self->request(
    resource => 'datasets',
    method => 'commit',
    dataset_id => $dataset_id,
    content => $content,
  );

  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return $response->{error}{message};
  } else {
    return $response;
  }

}

sub lookup {
  my ($self, %args) = @_;

  die "undefined keys to lookup" if !defined $args{keys};
  die "cannot specify both a read consistency and a transaction" if ( (defined $args{readConsistency}) && (defined $args{transaction}) );

  my $dataset_id = $args{dataset_id} // $self->{dataset_id};
  my $project_id = $args{project_id} // $self->{project_id};
  my @keys = $args{keys};

  my $content = {
    keys => \@keys
  };

  # options
  $content->{readOptions}{readConsistency} = $args{readConsistency} if defined $args{readConsistency};
  $content->{readOptions}{transaction} = $args{transaction} if defined $args{transaction};

  my $response = $self->request(
    resource => 'datasets',
    method => 'lookup',
    project_id => $project_id,
    dataset_id => $dataset_id,
    content => $content
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return $response->{error}{message};
  } else {
    return $response;
  }  
}

sub Key {
  my ($self, %args) = @_;
  my $class = 'Google::DataStore::Key';
	
  if (load_class($class)) {
    return $class->new();
  } else {
    die "Can't load class: $class";
  }  
}

sub rollback {

}

sub gqlQuery {
  my ($self, $query, %args) = @_;

  my $dataset_id = $args{dataset_id} // $self->{dataset_id};

  die "undefined query to run" if !defined $query;

  my $content->{gqlQuery}{queryString} = $query;

  my $response = $self->request(
    resource => 'datasets',
    method => 'runQuery',
    dataset_id => $dataset_id,
    content => $content
  );
  $self->{response} = $response;

  if (defined $response->{error}) {
    warn $response->{error}{message};
    return $response->{error}{message};
  } else {
    return $response->{batch}{entityResults};
  }  
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Google::DataStore - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Google::DataStore;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Google::DataStore, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Omar Yesith Alvarado González, E<lt>omaryesith@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Omar Yesith Alvarado González

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
