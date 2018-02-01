package Apache::OpenProjectRepoman;

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use File::Path qw(rmtree);
use File::Spec ();
use File::Copy qw(move);

use Apache2::Module;
use Apache2::Access;
use Apache2::ServerRec qw();
use Apache2::Response ();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::RequestIO qw();
use Apache2::Const -compile => qw(FORBIDDEN OK OR_AUTHCFG TAKE1 HTTP_UNPROCESSABLE_ENTITY HTTP_BAD_REQUEST OK);
use APR::Table ();

use JSON;
use Carp;


##
# Add AccessSecret directive to Apache, which is checked during configtest
my @directives = (
  {
    name => 'AccessSecret',
    req_override => Apache2::Const::OR_AUTHCFG,
    args_how => Apache2::Const::TAKE1,
    errmsg => 'Secret access token used to access the repository wrapper.',
  }
);
Apache2::Module::add(__PACKAGE__, \@directives);

##
# Accepts and tests the access secret value given in the Apache configuration
sub AccessSecret {
  my ($self, $parms, @args) = @_;
  $self->{token} = $args[0];
  unless (length($self->{token}) >= 8) {
    die "Use at least 8 characters for the repoman access token!";
  }
}

##
# Creates an actual repository on disk for Subversion and Git.
sub create_repository {
  my ($r, $vendor, $repository, $repository_root, $request) = @_;

  my $command = {
    git => "git init $repository --shared --bare",
    subversion => "svnadmin create $repository"
  }->{$vendor};

  die "No create command known for vendor '$vendor'\n" unless defined($command);
  die "Could not create repository.\n" unless system($command) == 0;
}

##
# Removes the repository with a given identifier on disk.
sub delete_repository {
  my ($r, $vendor, $repository, $repository_root, $request) = @_;
  rmtree($repository) if -d $repository;
}

sub relocate_repository {
  my ($r, $vendor, $repository, $repository_root, $request) = @_;

  # Determine validity of the old repository identifier as a dir name
  my $old_identifier = $request->{old_identifier};
  die ("Old repository identifier is empty") unless (length($old_identifier) > 0);
  die ("Old repository identifier is an invalid filename") if ($old_identifier =~ m{[\\/:*?"<>|]});

  my $old_repository = File::Spec->catdir($repository_root, $old_identifier);
  move($old_repository, $repository) if -d $old_repository;
}

##
# Extract and return JSON request from the Apache request handler.
sub parse_request {
  my $r = shift;
  my $len  = $r->headers_in->{'Content-Length'};

  die "Request invalid.\n"  unless (defined($len) && $len > 0);
  die "Request too large.\n"  if ($len > (2**13));

  my ($buf, $content);
  while($r->read($buf, $len)) {
    $content .= $buf;
  }

  my $json = JSON->new->allow_blessed->allow_nonref->convert_blessed;
  return $json->decode($content);
}

##
# Returns a JSON error and sets the HTTP response code to $type.
sub make_error {
    my ($r, $type, $msg) = @_;
    my $response = {
      success => JSON::false,
      message => $msg
    };

    $r->status($type) ;
    return $response;
  }

##
# Actual incoming request handler, that receives the JSON request
# and determines the necessary local action from the request.
sub _handle_request {
  my $r = shift;

  # Parse JSON request
  my $request = parse_request($r);

  # Get repository root for the current vendor
  my %paths = $r->dir_config->get('ScmVendorPaths');

  my $vendor = $request->{vendor};
  my $repository_root = $paths{$vendor};

  # Compare access token
  my $passed_token = $request->{token};
  my $cfg = Apache2::Module::get_config( __PACKAGE__, $r->server, $r->per_dir_config );

  unless (length($passed_token) >= 8 && ($passed_token eq $cfg->{token})) {
    return make_error($r, Apache2::Const::FORBIDDEN, 'Invalid access token');
  }

  # Abort unless repository root is configured in the Apache configuration
  unless (defined($repository_root)) {
    return make_error($r,
      Apache2::Const::HTTP_UNPROCESSABLE_ENTITY,
      "Vendor '$vendor' not configured.");
  }

  # Abort unless the repository root actually exists
  unless (-d $repository_root) {
    return make_error($r,
      Apache2::Const::HTTP_UNPROCESSABLE_ENTITY,
      "Repository path for vendor '$vendor' does not exist.");
  }

  # Determine validity of the identifier as a dir name
  my $repository_identifier = $request->{identifier};
  if ($repository_identifier =~ m{[\\/:*?"<>|]}) {
    return make_error($r,
      Apache2::Const::HTTP_UNPROCESSABLE_ENTITY,
      "Repository identifier is an invalid filename");
  }

  # Call the necessary action on disk
  my $target = File::Spec->catdir($repository_root, $repository_identifier);
  my %actions = (
    'create' => \&create_repository,
    'relocate' => \&relocate_repository,
    'delete' => \&delete_repository
    );

  my $action = $actions{$request->{action}};
  die "Unknown action.\n"  unless defined($action);
  $action->($r, $vendor, $target, $repository_root, $request);

  return {
    success => JSON::true,
    message => "The action has completed sucessfully.",
    repository => $target,
    path => $target,
    # This is only useful in the packager context
    url => 'file://' . $target
  };
}

##
# Handler subroutine that is called for each request by Apache
sub handler {
  my $r = shift;

  my $response;
  $r->content_type('application/json');

  eval {
    $response = _handle_request($r);
    1;
  } or do {
    my $err = $@;
    chomp $err;
    $response = make_error($r, Apache2::Const::HTTP_BAD_REQUEST, $err);
  };


  my $json = JSON->new->allow_blessed->allow_nonref->convert_blessed;
  print $json->encode($response);
  return Apache2::Const::OK;
}

1;
