package Apache::Authn::OpenProject;

=head1 Apache::Authn::OpenProject

OpenProject - a mod_perl module to authenticate webdav subversion users
against OpenProject database

=head1 SYNOPSIS

This module allow anonymous users to browse public project and
registred users to browse and commit their project. Authentication is
done against the OpenProject database or the LDAP configured in OpenProject.

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

If your OpenProject users use LDAP authentication, you will also need
Authen::Simple::LDAP (and IO::Socket::SSL if LDAPS is used):

  aptitude install libauthen-simple-ldap-perl libio-socket-ssl-perl

=head1 CONFIGURATION

   ## This module has to be in your perl path
   ## eg:  /usr/lib/perl5/Apache/Authn/OpenProject.pm
   PerlLoadModule Apache::Authn::OpenProject
   <Location /svn>
     DAV svn
     SVNParentPath "/var/svn"

     AuthType Basic
     AuthName openproject
     Require valid-user

     PerlAccessHandler Apache::Authn::OpenProject::access_handler
     PerlAuthenHandler Apache::Authn::OpenProject::authen_handler
  
     ## for mysql
     OpenProjectDSN "DBI:mysql:database=databasename;host=my.db.server"
     ## for postgres
     # OpenProjectDSN "DBI:Pg:dbname=databasename;host=my.db.server"

     OpenProjectDbUser "openproject"
     OpenProjectDbPass "password"
     ## Optional where clause (fulltext search would be slow and
     ## database dependant).
     # OpenProjectDbWhereClause "and members.role_id IN (1,2)"
     ## Optional credentials cache size
     # OpenProjectCacheCredsMax 50
  </Location>

To be able to browse repository inside openproject, you must add something
like that :

   <Location /svn-private>
     DAV svn
     SVNParentPath "/var/svn"
     Order deny,allow
     Deny from all
     # only allow reading orders
     <Limit GET PROPFIND OPTIONS REPORT>
       Allow from openproject.server.ip
     </Limit>
   </Location>

and you will have to use this reposman.rb command line to create repository :

  reposman.rb --redmine my.openproject.server --svn-dir /var/svn --owner www-data -u http://svn.server/svn-private/

=head1 MIGRATION FROM OLDER RELEASES

If you use an older reposman.rb (r860 or before), you need to change
rights on repositories to allow the apache user to read and write
S<them :>

  sudo chown -R www-data /var/svn/*
  sudo chmod -R u+w /var/svn/*

And you need to upgrade at least reposman.rb (after r860).

=head1 GIT SMART HTTP SUPPORT

Git's smart HTTP protocol (available since Git 1.7.0) will not work with the
above settings. OpenProject.pm normally does access control depending on the HTTP
method used: read-only methods are OK for everyone in public projects and
members with read rights in private projects. The rest require membership with
commit rights in the project.

However, this scheme doesn't work for Git's smart HTTP protocol, as it will use
POST even for a simple clone. Instead, read-only requests must be detected using
the full URL (including the query string): anything that doesn't belong to the
git-receive-pack service is read-only.

To activate this mode of operation, add this line inside your <Location /git>
block:

  OpenProjectGitSmartHttp yes

Here's a sample Apache configuration which integrates git-http-backend with
a MySQL database and this new option:

   SetEnv GIT_PROJECT_ROOT /var/www/git/
   SetEnv GIT_HTTP_EXPORT_ALL
   ScriptAlias /git/ /usr/libexec/git-core/git-http-backend/
   <Location /git>
       Order allow,deny
       Allow from all

       AuthType Basic
       AuthName Git
       Require valid-user

       PerlAccessHandler Apache::Authn::OpenProject::access_handler
       PerlAuthenHandler Apache::Authn::OpenProject::authen_handler
       # for mysql
       OpenProjectDSN "DBI:mysql:database=openproject;host=127.0.0.1"
       OpenProjectDbUser "openproject"
       OpenProjectDbPass "xxx"
       OpenProjectGitSmartHttp yes
    </Location>

Make sure that all the names of the repositories under /var/www/git/ match
exactly the identifier for some project: /var/www/git/myproject.git won't work,
due to the way this module extracts the identifier from the URL.
/var/www/git/myproject will work, though. You can put both bare and non-bare
repositories in /var/www/git, though bare repositories are strongly
recommended. You should create them with the rights of the user running OpenProject,
like this:

  cd /var/www/git
  sudo -u user-running-openproject mkdir myproject
  cd myproject
  sudo -u user-running-openproject git init --bare

Once you have activated this option, you have three options when cloning a
repository:

- Cloning using "http://user@host/git/repo" works, but will ask for the password
  all the time.

- Cloning with "http://user:pass@host/git/repo" does not have this problem, but
  this could reveal accidentally your password to the console in some versions
  of Git, and you would have to ensure that .git/config is not readable except
  by the owner for each of your projects.

- Use "http://host/git/repo", and store your credentials in the ~/.netrc
  file. This is the recommended solution, as you only have one file to protect
  and passwords will not be leaked accidentally to the console.

  IMPORTANT NOTE: It is *very important* that the file cannot be read by other
  users, as it will contain your password in cleartext. To create the file, you
  can use the following commands, replacing yourhost, youruser and yourpassword
  with the right values:

    touch ~/.netrc
    chmod 600 ~/.netrc
    echo -e "machine yourhost\nlogin youruser\npassword yourpassword" > ~/.netrc

=cut

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use DBI;
use Digest::SHA;
# optional module for LDAP authentication
my $CanUseLDAPAuth = eval("use Authen::Simple::LDAP; 1");

use Apache2::Module;
use Apache2::Access;
use Apache2::ServerRec qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::Const qw(:common :override :cmd_how);
use APR::Pool ();
use APR::Table ();

# use Apache2::Directive qw();

my @directives = (
  {
    name => 'OpenProjectDSN',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'Dsn in format used by Perl DBI. eg: "DBI:Pg:dbname=databasename;host=my.db.server"',
  },
  {
    name => 'OpenProjectDbUser',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'OpenProjectDbPass',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'OpenProjectDbWhereClause',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'OpenProjectCacheCredsMax',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'OpenProjectCacheCredsMax must be decimal number',
  },
  {
    name => 'OpenProjectGitSmartHttp',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
);

sub OpenProjectDSN { 
  my ($self, $parms, $arg) = @_;
  $self->{OpenProjectDSN} = $arg;
  my $query = "SELECT 
                 user_passwords.hashed_password, user_passwords.salt, users.auth_source_id, roles.permissions
              FROM members, projects, users, user_passwords, roles, member_roles
              WHERE 
                projects.id=members.project_id
                AND member_roles.member_id=members.id
                AND users.id=members.user_id 
                AND roles.id=member_roles.role_id
                AND users.status=1 
				AND users.id=user_passwords.user_id
                AND users.login=? 
                AND projects.identifier=? ";
  $self->{OpenProjectQuery} = trim($query);
}

sub OpenProjectDbUser { set_val('OpenProjectDbUser', @_); }
sub OpenProjectDbPass { set_val('OpenProjectDbPass', @_); }
sub OpenProjectDbWhereClause { 
  my ($self, $parms, $arg) = @_;
  $self->{OpenProjectQuery} = trim($self->{OpenProjectQuery}.($arg ? $arg : "")." ");
}

sub OpenProjectCacheCredsMax { 
  my ($self, $parms, $arg) = @_;
  if ($arg) {
    $self->{OpenProjectCachePool} = APR::Pool->new;
    $self->{OpenProjectCacheCreds} = APR::Table::make($self->{OpenProjectCachePool}, $arg);
    $self->{OpenProjectCacheCredsCount} = 0;
    $self->{OpenProjectCacheCredsMax} = $arg;
  }
}

sub OpenProjectGitSmartHttp {
  my ($self, $parms, $arg) = @_;
  $arg = lc $arg;

  if ($arg eq "yes" || $arg eq "true") {
    $self->{OpenProjectGitSmartHttp} = 1;
  } else {
    $self->{OpenProjectGitSmartHttp} = 0;
  }
}

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


my %read_only_methods = map { $_ => 1 } qw/GET PROPFIND REPORT OPTIONS/;

sub request_is_read_only {
  my ($r) = @_;
  my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);

  # Do we use Git's smart HTTP protocol, or not?
  if (defined $cfg->{OpenProjectGitSmartHttp} and $cfg->{OpenProjectGitSmartHttp}) {
    my $uri = $r->unparsed_uri;
    my $location = $r->location;
    my $is_read_only = $uri !~ m{^$location/*[^/]+/+(info/refs\?service=)?git\-receive\-pack$}o;
    return $is_read_only;
  } else {
    # Old behaviour: check the HTTP method
    my $method = $r->method;
    return defined $read_only_methods{$method};
  }
}

sub access_handler {
  my $r = shift;

  unless ($r->some_auth_required) {
      $r->log_reason("No authentication has been configured");
      return FORBIDDEN;
  }

  return OK unless request_is_read_only($r);

  my $project_id = get_project_identifier($r);

  $r->set_handlers(PerlAuthenHandler => [\&OK])
      if is_public_project($project_id, $r) && anonymous_role_allows_browse_repository($r);

  return OK
}

sub authen_handler {
  my $r = shift;
  
  my ($res, $openproject_pass) =  $r->get_basic_auth_pw();
  return $res unless $res == OK;
  
  if (is_member($r->user, $openproject_pass, $r)) {
      return OK;
  } else {
      $r->note_auth_failure();
      return AUTH_REQUIRED;
  }
}

# check if authentication is forced
sub is_authentication_forced {
  my $r = shift;

  my $dbh = connect_database($r);
  my $sth = $dbh->prepare(
    "SELECT value FROM settings where settings.name = 'login_required';"
  );

  $sth->execute();
  my $ret = 0;
  if (my @row = $sth->fetchrow_array) {
    if ($row[0] eq "1" || $row[0] eq "t") {
      $ret = 1;
    }
  }
  $sth->finish();
  undef $sth;
  
  $dbh->disconnect();
  undef $dbh;

  $ret;
}

sub is_public_project {
    my $project_id = shift;
    my $r = shift;
    
    if (is_authentication_forced($r)) {
      return 0;
    }

    my $dbh = connect_database($r);
    my $sth = $dbh->prepare(
        "SELECT is_public FROM projects WHERE projects.identifier = ?;"
    );

    $sth->execute($project_id);
    my $ret = 0;
    if (my @row = $sth->fetchrow_array) {
    	if ($row[0] eq "1" || $row[0] eq "t") {
    		$ret = 1;
    	}
    }
    $sth->finish();
    undef $sth;
    $dbh->disconnect();
    undef $dbh;

    $ret;
}

sub anonymous_role_allows_browse_repository {
  my $r = shift;
  
  my $dbh = connect_database($r);
  my $sth = $dbh->prepare(
      "SELECT permissions FROM roles WHERE builtin = 2;"
  );
  
  $sth->execute();
  my $ret = 0;
  if (my @row = $sth->fetchrow_array) {
    if ($row[0] =~ /:browse_repository/) {
      $ret = 1;
    }
  }
  $sth->finish();
  undef $sth;
  $dbh->disconnect();
  undef $dbh;
  
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
  my $openproject_user = shift;
  my $openproject_pass = shift;
  my $r = shift;

  my $dbh         = connect_database($r);
  my $project_id  = get_project_identifier($r);

  my $pass_digest = Digest::SHA::sha1_hex($openproject_pass);

  my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
  my $usrprojpass;
  if ($cfg->{OpenProjectCacheCredsMax}) {
    $usrprojpass = $cfg->{OpenProjectCacheCreds}->get($openproject_user.":".$project_id);
    return 1 if (defined $usrprojpass and ($usrprojpass eq $pass_digest));
  }
  my $query = $cfg->{OpenProjectQuery};
  my $sth = $dbh->prepare($query);
  $sth->execute($openproject_user, $project_id);

  my $ret;
  while (my ($hashed_password, $salt, $auth_source_id, $permissions) = $sth->fetchrow_array) {

      unless ($auth_source_id) {
        my $method = $r->method;
        my $salted_password = Digest::SHA::sha1_hex($salt.$pass_digest);
        if ($hashed_password eq $salted_password && ((request_is_read_only($r) && $permissions =~ /:browse_repository/) || $permissions =~ /:commit_access/) ) {
              $ret = 1;
              last;
          }
      } elsif ($CanUseLDAPAuth) {
          my $sthldap = $dbh->prepare(
              "SELECT host,port,tls,account,account_password,base_dn,attr_login from auth_sources WHERE id = ?;"
          );
          $sthldap->execute($auth_source_id);
          while (my @rowldap = $sthldap->fetchrow_array) {
            my $ldap = Authen::Simple::LDAP->new(
                host    =>      ($rowldap[2] eq "1" || $rowldap[2] eq "t") ? "ldaps://$rowldap[0]:$rowldap[1]" : $rowldap[0],
                port    =>      $rowldap[1],
                basedn  =>      $rowldap[5],
                binddn  =>      $rowldap[3] ? $rowldap[3] : "",
                bindpw  =>      $rowldap[4] ? $rowldap[4] : "",
                filter  =>      "(".$rowldap[6]."=%s)"
            );
            $ret = 1 if ($ldap->authenticate($openproject_user, $openproject_pass) && ((request_is_read_only($r) && $permissions =~ /:browse_repository/) || $permissions =~ /:commit_access/));
          }
          $sthldap->finish();
          undef $sthldap;
      }
  }
  $sth->finish();
  undef $sth;
  $dbh->disconnect();
  undef $dbh;

  if ($cfg->{OpenProjectCacheCredsMax} and $ret) {
    if (defined $usrprojpass) {
      $cfg->{OpenProjectCacheCreds}->set($openproject_user.":".$project_id, $pass_digest);
    } else {
      if ($cfg->{OpenProjectCacheCredsCount} < $cfg->{OpenProjectCacheCredsMax}) {
        $cfg->{OpenProjectCacheCreds}->set($openproject_user.":".$project_id, $pass_digest);
        $cfg->{OpenProjectCacheCredsCount}++;
      } else {
        $cfg->{OpenProjectCacheCreds}->clear();
        $cfg->{OpenProjectCacheCredsCount} = 0;
      }
    }
  }

  $ret;
}

sub get_project_identifier {
    my $r = shift;
    
    my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
    my $location = $r->location;
    my ($identifier) = $r->uri =~ m{$location/*([^/]+)};
    $identifier =~ s/\.git$// if (defined $cfg->{OpenProjectGitSmartHttp} and $cfg->{OpenProjectGitSmartHttp});
    $identifier;
}

sub connect_database {
    my $r = shift;
    
    my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
    return DBI->connect($cfg->{OpenProjectDSN}, $cfg->{OpenProjectDbUser}, $cfg->{OpenProjectDbPass});
}

1;
