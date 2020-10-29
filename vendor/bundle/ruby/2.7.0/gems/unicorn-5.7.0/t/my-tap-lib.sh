#!/bin/sh
# Copyright (c) 2009, 2010 Eric Wong <normalperson@yhbt.net>
#
# TAP-producing shell library for POSIX-compliant Bourne shells We do
# not _rely_ on Bourne Again features, though we will use "set -o
# pipefail" from ksh93 or bash 3 if available
#
# Only generic, non-project/non-language-specific stuff goes here.  We
# only have POSIX dependencies for the core tests (without --verbose),
# though we'll enable useful non-POSIX things if they're available.
#
# This test library is intentionally unforgiving, it does not support
# skipping tests nor continuing after any failure.  Any failures
# immediately halt execution as do any references to undefined
# variables.
#
# When --verbose is specified, we always prefix stdout/stderr
# output with "#" to avoid confusing TAP consumers.  Otherwise
# the normal stdout/stderr streams are redirected to /dev/null

# dup normal stdout(fd=1) and stderr (fd=2) to fd=3 and fd=4 respectively
# normal TAP output goes to fd=3, nothing should go to fd=4
exec 3>&1 4>&2

# ensure a sane environment
TZ=UTC LC_ALL=C LANG=C
export LANG LC_ALL TZ
unset CDPATH

# pipefail is non-POSIX, but very useful in ksh93/bash
( set -o pipefail 2>/dev/null ) && set -o pipefail

SED=${SED-sed}

# Unlike other test frameworks, we are unforgiving and bail immediately
# on any failures.  We do this because we're lazy about error handling
# and also because we believe anything broken should not be allowed to
# propagate throughout the rest of the test
set -e
set -u

# name of our test
T=${0##*/}

t_expect_nr=-1
t_nr=0
t_current=
t_complete=false

# list of files to remove unconditionally on exit
T_RM_LIST=

# list of files to remove only on successful exit
T_OK_RM_LIST=

# emit output to stdout, it'll be parsed by the TAP consumer
# so it must be TAP-compliant output
t_echo () {
	echo >&3 "$@"
}

# emits non-parsed information to stdout, it will be prefixed with a '#'
# to not throw off TAP consumers
t_info () {
	t_echo '#' "$@"
}

# exit with an error and print a diagnostic
die () {
	echo >&2 "$@"
	exit 1
}

# our at_exit handler, it'll fire for all exits except SIGKILL (unavoidable)
t_at_exit () {
	code=$?
	set +e
	if test $code -eq 0
	then
		$t_complete || {
			t_info "t_done not called"
			code=1
		}
	elif test -n "$t_current"
	then
		t_echo "not ok $t_nr - $t_current"
	fi
	if test $t_expect_nr -ne -1
	then
		test $t_expect_nr -eq $t_nr || {
			t_info "planned $t_expect_nr tests but ran $t_nr"
			test $code -ne 0 || code=1
		}
	fi
	$t_complete || {
		t_info "unexpected test failure"
		test $code -ne 0 || code=1
	}
	rm -f $T_RM_LIST
	test $code -eq 0 && rm -f $T_OK_RM_LIST
	set +x
	exec >&3 2>&4
	t_close_fds
	exit $code
}

# close test-specific extra file descriptors
t_close_fds () {
	exec 3>&- 4>&-
}

# call this at the start of your test to specify the number of tests
# you plan to run
t_plan () {
	test "$1" -ge 1 || die "must plan at least one test"
	test $t_expect_nr -eq -1 || die "tried to plan twice in one test"
	t_expect_nr=$1
	shift
	t_echo 1..$t_expect_nr "#" "$@"
	trap t_at_exit EXIT
}

_t_checkup () {
	test $t_expect_nr -le 0 && die "no tests planned"
	test -n "$t_current" && t_echo "ok $t_nr - $t_current"
	true
}

# finalizes any previously test and starts a new one
t_begin () {
	_t_checkup
	t_nr=$(( $t_nr + 1 ))
	t_current="$1"

	# just in case somebody wanted to cheat us:
	set -e
}

# finalizes the current test without starting a new one
t_end () {
	_t_checkup
	t_current=
}

# run this to signify the end of your test
t_done () {
	_t_checkup
	t_current=
	t_complete=true
	test $t_expect_nr -eq $t_nr || exit 1
	exit 0
}

# create and assign named-pipes to variable _names_ passed to this function
t_fifos () {
	for _id in "$@"
	do
		_name=$_id
		_tmp=$(mktemp -t $T.$$.$_id.XXXXXXXX)
		eval "$_id=$_tmp"
		rm -f $_tmp
		mkfifo $_tmp
		T_RM_LIST="$T_RM_LIST $_tmp"
	done
}

t_verbose=false t_trace=false

while test "$#" -ne 0
do
	arg="$1"
	shift
	case $arg in
	-v|--verbose) t_verbose=true ;;
	--trace) t_trace=true t_verbose=true ;;
	*) die "Unknown option: $arg" ;;
	esac
done

# we always only setup stdout, nothing should end up in the "real" stderr
if $t_verbose
then
	if test x"$(which mktemp 2>/dev/null)" = x
	then
		die "mktemp(1) not available for --verbose"
	fi
	t_fifos t_stdout t_stderr

	(
		# use a subshell so seds are not waitable
		$SED -e 's/^/#: /' < $t_stdout &
		$SED -e 's/^/#! /' < $t_stderr &
	) &
	wait
	exec > $t_stdout 2> $t_stderr
else
	exec > /dev/null 2> /dev/null
fi

$t_trace && set -x
true
