package Apache::Authn::Redmine;

=head1 Apache::Authn::Redmine

Redmine - a mod_perl module to authenticate webdav subversion users
against redmine database

=head1 SYNOPSIS

This module allow anonymous users to browse public project and
registred users to browse and commit their project. authentication is
done on the redmine database.

This method is far simpler than the one with pam_* and works with all
database without an hassle but you need to have apache/mod_perl on the
svn server.

=head1 INSTALLATION

For this to automagically work, you need to have a recent reposman.rb
(after r860) and if you already use reposman, read the last section to
migrate.

Sorry ruby users but you need some perl modules, at least mod_perl2,
DBI and DBD::mysql (or the DBD driver for you database as it should
work on allmost all databases).

On debian/ubuntu you must do :

  aptitude install libapache-dbi-perl libapache2-mod-perl2 libdbd-mysql-perl

=head1 CONFIGURATION

   ## if the module isn't in your perl path
   PerlRequire /usr/local/apache/Redmine.pm
   ## else
   # PerlModule Apache::Authn::Redmine
   <Location /svn>
     DAV svn
     SVNParentPath "/var/svn"

     AuthType Basic
     AuthName redmine
     Require valid-user

     PerlAccessHandler Apache::Authn::Redmine::access_handler
     PerlAuthenHandler Apache::Authn::Redmine::authen_handler
  
     ## for mysql
     PerlSetVar dsn DBI:mysql:database=databasename;host=my.db.server
     ## for postgres
     # PerlSetVar dsn DBI:Pg:dbname=databasename;host=my.db.server

     PerlSetVar db_user redmine
     PerlSetVar db_pass password
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

use DBI;
use Digest::SHA1;
use Authen::Simple::LDAP;

use Apache2::Module;
use Apache2::Access;
use Apache2::ServerRec qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::Const qw(:common);
# use Apache2::Directive qw();

my %read_only_methods = map { $_ => 1 } qw/GET PROPFIND REPORT OPTIONS/;

sub access_handler {
  my $r = shift;

  unless ($r->some_auth_required) {
      $r->log_reason("No authentication has been configured");
      return FORBIDDEN;
  }

  my $method = $r->method;
  return OK unless 1 == $read_only_methods{$method};

  my $project_id = get_project_identifier($r);

  $r->set_handlers(PerlAuthenHandler => [\&OK])
      if is_public_project($project_id, $r);

  return OK
}

sub authen_handler {
  my $r = shift;
  
  my ($res, $redmine_pass) =  $r->get_basic_auth_pw();
  return $res unless $res == OK;
  
  if (is_member($r->user, $redmine_pass, $r)) {
      return OK;
  } else {
      $r->note_auth_failure();
      return AUTH_REQUIRED;
  }
}

sub is_public_project {
    my $project_id = shift;
    my $r = shift;

    my $dbh = connect_database($r);
    my $sth = $dbh->prepare(
        "SELECT * FROM projects WHERE projects.identifier=? and projects.is_public=true;"
    );

    $sth->execute($project_id);
    my $ret = $sth->fetchrow_array ? 1 : 0;
    $dbh->disconnect();

    $ret;
}

# perhaps we should use repository right (other read right) to check public access.
# it could be faster BUT it doesn't work for the moment.
# sub is_public_project_by_file {
#     my $project_id = shift;
#     my $r = shift;

#     my $tree = Apache2::Directive::conftree();
#     my $node = $tree->lookup('Location', $r->location);
#     my $hash = $node->as_hash;

#     my $svnparentpath = $hash->{SVNParentPath};
#     my $repos_path = $svnparentpath . "/" . $project_id;
#     return 1 if (stat($repos_path))[2] & 00007;
# }

sub is_member {
  my $redmine_user = shift;
  my $redmine_pass = shift;
  my $r = shift;

  my $dbh         = connect_database($r);
  my $project_id  = get_project_identifier($r);

  my $pass_digest = Digest::SHA1::sha1_hex($redmine_pass);

  my $sth = $dbh->prepare(
      "SELECT hashed_password, auth_source_id FROM members, projects, users WHERE projects.id=members.project_id AND users.id=members.user_id AND users.status=1 AND login=? AND identifier=?;"
  );
  $sth->execute($redmine_user, $project_id);

  my $ret;
  while (my @row = $sth->fetchrow_array) {
      unless ($row[1]) {
          if ($row[0] eq $pass_digest) {
              $ret = 1;
              last;
          }
      } else {
          my $sthldap = $dbh->prepare(
              "SELECT host,port,account,account_password,base_dn,attr_login from auth_sources WHERE id = ?;"
          );
          $sthldap->execute($row[1]);
          while (my @rowldap = $sthldap->fetchrow_array) {
            my $ldap = Authen::Simple::LDAP->new(
	        host 	=>	$rowldap[0],
		port	=>	$rowldap[1],
		basedn	=>	$rowldap[4],
		binddn	=>	$rowldap[2] ? $rowldap[2] : "",
		bindpw	=>	$rowldap[3] ? $rowldap[3] : "",
		filter	=>	"(".$rowldap[5]."=%s)"
	    );
	    $ret = 1 if ($ldap->authenticate($redmine_user, $redmine_pass));
          }
          $sthldap->finish();
      }
  }
  $sth->finish();
  $dbh->disconnect();

  $ret;
}

sub get_project_identifier {
    my $r = shift;
    
    my $location = $r->location;
    my ($identifier) = $r->uri =~ m{$location/*([^/]+)};
    $identifier;
}

sub connect_database {
    my $r = shift;

    my ($dsn, $db_user, $db_pass) = map { $r->dir_config($_) } qw/dsn db_user db_pass/;
    return DBI->connect($dsn, $db_user, $db_pass);
}

1;
