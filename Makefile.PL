use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Google::DataStore',
    VERSION_FROM      => 'lib/Google/DataStore.pm', # finds $VERSION
    PREREQ_PM         => {
    	'Class::Load' => 0,
    	'Crypt::OpenSSL::PKCS12' => '0.7',
    	'JSON' => 0,
    	'JSON::WebToken', => 0,
    	'LWP::UserAgent' => 0,
    	'Net::SSLeay' => 0

    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Google/DataStore.pm', # retrieve abstract from module
       AUTHOR         => 'Omar Yesith Alvarado González <omarjesith@gmail.com>') : ()),
);
