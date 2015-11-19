Google-DataStore version 0.01
=============================
   Google::DataStore - Perl Client Library for Google DataStore
   
   Provides access to "Google DataStore", this initial version allows:
   
   - Make lookup
   - Initialize transactions
   - Commit (missing many validations for including mutations, but it works)
   - Send a simple query with GqlQuery
# NAME
   Google::DataStore - Perl Client Library for Google DataStore

# INSTALLATION

To install this module type the following:

   * perl Makefile.PL
   * make
   * make test
   * make install

#DEPENDENCIES

This module requires these other modules and libraries:

# SYNOPSIS
   use Google::DataStore;
   
   my $client_email = <YOUR_CLIENT_EMAIL_ADDRESS>;
   my $private_key_file = <YOUR_PRIVATE_KEY_FILE>;
   my $project_id = <YOUR_PROJECT_ID>;
   
   my $datastore = Google::DataStore::create(
      client_email => $client_email,
      private_key_file => $private_key_file,
      project_id => $project_id,
   );
   
   #define the dataset to use
   $datastore->use_dataset('<YOUR_DATASET_ID>');

   #let's do a simple Lookup
   #create a new key
   my $key = $datastore->Key();
   #Add the path element to the key
   my $path = $key->AddPathElement(kind=>'Trivia', name=>'hgtg');
   
   #the lookup
   my $resp = $datastore->lookup(keys=>$key->{key});
   if (defined $resp->{found}[0]){
      my $entity = $resp->{found}[0]{entity};
      #This is only to see the entity
      use Dumper::Data;
      print Dumper($entity);
   }

# COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) 2015 by Omar Yesith Alvarado González - omarjesith@gmail.com

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.
