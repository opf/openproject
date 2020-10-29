#!/usr/bin/perl -w
# Benchmark script to spawn some processes and hammer a local unicorn
# to test accept loop performance.  This only does Unix sockets.
# There's plenty of TCP benchmarking tools out there, and TCP port reuse
# has predictability problems since unicorn can't do persistent connections.
# Written in Perl for the same reason: predictability.
# Ruby GC is not as predictable as Perl refcounting.
use strict;
use Socket qw(AF_UNIX SOCK_STREAM sockaddr_un);
use POSIX qw(:sys_wait_h);
use Getopt::Std;
# -c / -n switches stolen from ab(1)
my $usage = "$0 [-c CONCURRENCY] [-n NUM_REQUESTS] SOCKET_PATH\n";
our $opt_c = 2;
our $opt_n = 1000;
getopts('c:n:') or die $usage;
my $unix_path = shift or die $usage;
use constant REQ => "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n";
use constant REQ_LEN => length(REQ);
use constant BUFSIZ => 8192;
$^F = 99; # don't waste syscall time with FD_CLOEXEC

my %workers; # pid => worker num
die "-n $opt_n not evenly divisible by -c $opt_c\n" if $opt_n % $opt_c;
my $n_per_worker = $opt_n / $opt_c;
my $addr = sockaddr_un($unix_path);

for my $num (1..$opt_c) {
	defined(my $pid = fork) or die "fork failed: $!\n";
	if ($pid) {
		$workers{$pid} = $num;
	} else {
		work($n_per_worker);
	}
}

reap_worker(0) while scalar keys %workers;
exit;

sub work {
	my ($n) = @_;
	my ($buf, $x);
	for (1..$n) {
		socket(S, AF_UNIX, SOCK_STREAM, 0) or die "socket: $!";
		connect(S, $addr) or die "connect: $!";
		defined($x = syswrite(S, REQ)) or die "write: $!";
		$x == REQ_LEN or die "short write: $x != ".REQ_LEN."\n";
		do {
			$x = sysread(S, $buf, BUFSIZ);
			unless (defined $x) {
				next if $!{EINTR};
				die "sysread: $!\n";
			}
		} until ($x == 0);
	}
	exit 0;
}

sub reap_worker {
	my ($flags) = @_;
	my $pid = waitpid(-1, $flags);
	return if !defined $pid || $pid <= 0;
	my $p = delete $workers{$pid} || '(unknown)';
	warn("$pid [$p] exited with $?\n") if $?;
	$p;
}
