#!/usr/bin/perl
#
# redMine is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

use strict;
use SOAP::Lite;
use Getopt::Long;
Getopt::Long::Configure ("bundling", "no_auto_abbrev", "no_ignore_case");
use Pod::Usage;
use vars qw/$VERSION/;

$VERSION = "1.0";

my %opts = (verbose => 0);
GetOptions(\%opts, 'verbose|v+', 'version|V', 'help|h', 'man|m', 'quiet|q', 'svn-dir|s=s', 'redmine-host|r=s') or pod2usage(2);

die "$VERSION\n"           if $opts{version};
pod2usage(1)               if $opts{help};
pod2usage( -verbose => 2 ) if $opts{man};

my $repos_base = $opts{'svn-dir'};
my $redmine_host = $opts{'redmine-host'};

pod2usage(2) unless $repos_base and $redmine_host;

unless (-d $repos_base) {
    Log(text => "$repos_base doesn't exist", exit => 1);
}

Log(level => 1, text => "querying redMine for projects...");
my $wdsl = "http://$redmine_host/sys/service.wsdl";
my $service = SOAP::Lite->service($wdsl);

my $projects = $service->Projects('');
my $project_count = @{$projects};
Log(level => 1, text => "retrieved $project_count projects");

foreach my $project (@{$projects}) {
    Log(level => 1, text => "treating project $project->{name}");
    my $repos_name = $project->{identifier};

    if ($repos_name eq "") {
        Log(text => "\tno identifier for project $project->{name}");
        next;
    }

    unless ($repos_name =~ /^[a-z0-9\-]+$/) {
        Log(text => "\tinvalid identifier for project $project->{name}");
        next;
    }

    my $repos_path = "$repos_base/$repos_name";

    if (-e $repos_path) {
    	# check unix right and change them if needed
    	my $other_read = (stat($repos_path))[2] & 00007;
	    my $right;

	    if ($project->{is_public} and not $other_read) {
	        $right = "0775";
	    } elsif (not $project->{is_public} and $other_read) {
	        $right = "0770";
	    } else {
	        next;
	    }
		
		# change mode	
	    system('chmod', '-R', $right, $repos_path) == 0 or
	        warn("\tunable to change mode on $repos_path : $?\n"), next;
	
	    Log(text => "\tmode change on $repos_path");
    	    
    } else {    
	    # change umask to suit the repository's privacy
	    $project->{is_public} ? umask 0002 : umask 0007;
	    
		# create the repository
	    system('svnadmin', 'create', $repos_path) == 0 or
	        warn("\tsystem svnadmin failed unable to create $repos_path\n"), next;
	        
		# set the group owner
	    system('chown', '-R', "root:$repos_name", $repos_path) == 0 or
	        warn("\tunable to create $repos_path : $?\n"), next;

	    Log(text => "\trepository $repos_path created");
	}
}


sub Log {
    my %args = (level => 0, text => '', @_);

    my $level = delete $args{level};
    my $text  = delete $args{text};
    return unless $level <= $opts{verbose};
    return if $opts{quiet};
    print "$text\n";

    exit $args{exit}
        if defined $args{exit};
}


__END__

=head1 NAME

 reposman - manages your svn repositories with redMine

=head1 SYNOPSIS

 reposman [options] arguments
 example: reposman --svn-dir=/var/svn --redmine-host=redmine.mydomain.foo
          reposman -s /var/svn -r redmine.mydomain.foo

=head1 ARGUMENTS

 -s, --svn-dir=DIR        use DIR as base directory for svn repositories
 -r, --redmine-host=HOST  assume redMine is hosted on HOST

=head1 OPTIONS

 -v                       verbose
 -V                       print version and exit

