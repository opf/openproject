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

my $wdsl = 'http://192.168.0.10:3000/sys/service.wsdl';
my $service = SOAP::Lite->service($wdsl);
my $repos_base = '/var/svn';

my $projects = $service->Projects('');

foreach my $project (@{$projects}) {
    my $repos_name = $project->{identifier};

    if ($repos_name eq "") {
        print("\tno identifier for project $project->{name}\n");
        next;
    }

    unless ($repos_name =~ /^[a-z0-9\-]+$/) {
        print("\tinvalid identifier for project $project->{name}\n");
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
	
	    print "\tmode change on $repos_path\n";
    	    
    } else {    
	    # change umask to suit the repository's privacy
	    $project->{is_public} ? umask 0002 : umask 0007;
	    
		# create the repository
	    system('svnadmin', 'create', $repos_path) == 0 or
	        warn("\tsystem svnadmin failed unable to create $repos_path\n"), next;
	        
		# set the group owner
	    system('chown', '-R', "root:$repos_name", $repos_path) == 0 or
	        warn("\tunable to create $repos_path : $?\n"), next;

	    print "\trepository $repos_path created\n";
	    my $call = $service->RepositoryCreated($project->{id}, "svn://host/$repos_name");
	}
}
