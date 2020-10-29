#!/bin/sh
. ./test-lib.sh
t_plan 8 "SIGTTIN succeeds after SIGWINCH"

t_begin "setup and start" && {
	unicorn_setup
cat >> $unicorn_config <<EOF
after_fork do |server, worker|
  # test script will block while reading from $fifo,
  File.open("$fifo", "wb") { |fp| fp.syswrite worker.nr.to_s }
end
EOF
	unicorn -D -c $unicorn_config pid.ru
	unicorn_wait_start
	test 0 -eq $(cat $fifo) || die "worker.nr != 0"
}

t_begin "read worker pid" && {
	orig_worker_pid=$(curl -sSf http://$listen/)
	test -n "$orig_worker_pid" && kill -0 $orig_worker_pid
}

t_begin "stop all workers" && {
	kill -WINCH $unicorn_pid
}

# we have to do this next step before delivering TTIN
# signals aren't guaranteed to delivered in order
t_begin "wait for worker to die" && {
	i=0
	while kill -0 $orig_worker_pid 2>/dev/null
	do
		i=$(( $i + 1 ))
		test $i -lt 600 || die "timed out"
		sleep 1
	done
}

t_begin "start one worker back up" && {
	kill -TTIN $unicorn_pid
}

t_begin "wait for new worker to start" && {
	test 0 -eq $(cat $fifo) || die "worker.nr != 0"
	new_worker_pid=$(curl -sSf http://$listen/)
	test -n "$new_worker_pid" && kill -0 $new_worker_pid
	test $orig_worker_pid -ne $new_worker_pid || \
	   die "worker wasn't replaced"
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && check_stderr

dbgcat r_err

t_done
