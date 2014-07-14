package Apache::Authn::Redmine;

=head1 Apache::Authn::Redmine

Redmine - a mod_perl module to authenticate webdav subversion users
against an OpenProject web service

=head1 SYNOPSIS

This module allow anonymous users to browse public project and
registred users to browse and commit their project. Authentication is
done against an OpenProject web service.

=head1 INSTALLATION

For this to automagically work, you need to have a recent reposman.rb
(after r860) and if you already use reposman, read the last section to
migrate.

Sorry ruby users but you need some perl modules, at least mod_perl2.

On debian/ubuntu you must do :

  aptitude install libapache2-mod-perl2

=head1 CONFIGURATION

   ## This module has to be in your perl path
   ## eg:  /usr/lib/perl5/Apache/Authn/OpenProjectAuthentication.pm
   PerlLoadModule Apache::Authn::OpenProjectAuthentication
   <Location /svn>
     DAV svn
     SVNParentPath "/var/svn"

     AuthType Basic
     AuthName OpenProject
     Require valid-user

     PerlAccessHandler Apache::Authn::Redmine::access_handler
     PerlAuthenHandler Apache::Authn::Redmine::authen_handler

    RedmineUrl "http://example.com/openproject/"
    RedmineApiKey "<API key>"
  </Location>

To be able to browse repository inside redmine, you must add something
like that :

   <Location /svn-private>
     DAV svn
     SVNParentPath "/var/svn"
     Order deny,allow
     Deny from all
     # only allow reading orders
     <Limit GET PROPFIND OPTIONS REPORT>
       Allow from redmine.server.ip
     </Limit>
   </Location>

and you will have to use this reposman.rb command line to create repository :

  reposman.rb --redmine my.redmine.server --svn-dir /var/svn --owner www-data -u http://svn.server/svn-private/

=head1 MIGRATION FROM OLDER RELEASES

If you use an older reposman.rb (r860 or before), you need to change
rights on repositories to allow the apache user to read and write
S<them :>

  sudo chown -R www-data /var/svn/*
  sudo chmod -R u+w /var/svn/*

And you need to upgrade at least reposman.rb (after r860).

=cut

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use Digest::SHA1;

use Apache2::Module;
use Apache2::Access;
use Apache2::ServerRec qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::Const qw(:common :override :cmd_how);
use APR::Pool ();
use APR::Table ();

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

# use Apache2::Directive qw();

my @directives = (
  {
    name => 'RedmineUrl',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'URL of your (local) OpenProject. (e.g. http://localhost/ or http://www.example.com/openproject/)',
  },
  {
    name => 'RedmineApiKey',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
);

sub RedmineUrl { set_val('RedmineUrl', @_); }
sub RedmineApiKey { set_val('RedmineApiKey', @_); }

sub trim {
  my $string = shift;
  $string =~ s/\s{2,}/ /g;
  return $string;
}

sub set_val {
  my ($key, $self, $parms, $arg) = @_;
  $self->{$key} = $arg;
}

Apache2::Module::add(__PACKAGE__, \@directives);

sub access_handler {
  my $r = shift;

  unless ($r->some_auth_required) {
   $r->log_reason("No authentication has been configured");
   return FORBIDDEN;
  }

  return OK
}

sub authen_handler {
  my $r = shift;

  my ($status, $password) = $r->get_basic_auth_pw();
  my $login = $r->user;

  return $status unless $status == OK;

  my $identifier = get_project_identifier($r);
  my $method = $r->method;

  if( is_access_allowed( $login, $password, $identifier, $method, $r ) ) {
    return OK;
  } else {
    $r->note_auth_failure();
    return AUTH_REQUIRED;
  }
}

# we send a request to the redmine sys api
# and use the user's given login and password for basic auth
# for accessing the redmine sys api an api key is needed
sub is_access_allowed {
  my $login = shift;
  my $password = shift;
  my $identifier = shift;
  my $method = shift;
  my $r = shift;

  my $cfg = Apache2::Module::get_config( __PACKAGE__, $r->server, $r->per_dir_config );

  my $key = $cfg->{RedmineApiKey};
  my $redmine_url = $cfg->{RedmineUrl} . '/sys/repo_auth';

  my $redmine_req = POST $redmine_url , [ repository => $identifier, key => $key, method => $method ];
  $redmine_req->authorization_basic( $login, $password );

  my $ua = LWP::UserAgent->new;
  my $response = $ua->request($redmine_req);

  return $response->is_success();
}

sub get_project_identifier {
    my $r = shift;

    my $location = $r->location;
    my ($identifier) = $r->uri =~ m{$location/*([^/]+)};
    $identifier;
}

1;
