#!/bin/sh
. ./test-lib.sh

t_plan 5 "at_exit/END handlers work as expected"

t_begin "setup and startup" && {
	unicorn_setup
	cat >> $unicorn_config <<EOF
at_exit { \$stdout.syswrite("#{Process.pid} BOTH\\n") }
END { \$stdout.syswrite("#{Process.pid} END BOTH\\n") }
after_fork do |_,_|
  at_exit { \$stdout.syswrite("#{Process.pid} WORKER ONLY\\n") }
  END { \$stdout.syswrite("#{Process.pid} END WORKER ONLY\\n") }
end
EOF

	unicorn -D pid.ru -c $unicorn_config
	unicorn_wait_start
}

t_begin "read worker PID" && {
	worker_pid=$(curl -sSf http://$listen/)
	t_info "worker_pid=$worker_pid"
}

t_begin "issue graceful shutdown (SIGQUIT) and wait for termination" && {
	kill -QUIT $unicorn_pid

	while kill -0 $unicorn_pid >/dev/null 2>&1
	do
		sleep 1
	done
}

t_begin "check stderr" && check_stderr

dbgcat r_err
dbgcat r_out

t_begin "all at_exit handlers ran" && {
	grep "$worker_pid BOTH" $r_out
	grep "$unicorn_pid BOTH" $r_out
	grep "$worker_pid END BOTH" $r_out
	grep "$unicorn_pid END BOTH" $r_out
	grep "$worker_pid WORKER ONLY" $r_out
	grep "$worker_pid END WORKER ONLY" $r_out
}

t_done
