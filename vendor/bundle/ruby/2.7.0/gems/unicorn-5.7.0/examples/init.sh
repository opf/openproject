#!/bin/sh
set -e
### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop unicorn Rack app server
### END INIT INFO

# Example init script, this can be used with nginx, too,
# since nginx and unicorn accept the same signals.

# Feel free to change any of the following variables for your app:
TIMEOUT=${TIMEOUT-60}
APP_ROOT=/home/x/my_app/current
PID=$APP_ROOT/tmp/pids/unicorn.pid
CMD="/usr/bin/unicorn -D -c $APP_ROOT/config/unicorn.rb"
INIT_CONF=$APP_ROOT/config/init.conf
UPGRADE_DELAY=${UPGRADE_DELAY-2}
action="$1"
set -u

test -f "$INIT_CONF" && . $INIT_CONF

OLD="$PID.oldbin"

cd $APP_ROOT || exit 1

sig () {
	test -s "$PID" && kill -$1 $(cat $PID)
}

oldsig () {
	test -s "$OLD" && kill -$1 $(cat $OLD)
}

case $action in
start)
	sig 0 && echo >&2 "Already running" && exit 0
	$CMD
	;;
stop)
	sig QUIT && exit 0
	echo >&2 "Not running"
	;;
force-stop)
	sig TERM && exit 0
	echo >&2 "Not running"
	;;
restart|reload)
	sig HUP && echo reloaded OK && exit 0
	echo >&2 "Couldn't reload, starting '$CMD' instead"
	$CMD
	;;
upgrade)
	if oldsig 0
	then
		echo >&2 "Old upgraded process still running with $OLD"
		exit 1
	fi

	cur_pid=
	if test -s "$PID"
	then
		cur_pid=$(cat $PID)
	fi

	if test -n "$cur_pid" &&
			kill -USR2 "$cur_pid" &&
			sleep $UPGRADE_DELAY &&
			new_pid=$(cat $PID) &&
			test x"$new_pid" != x"$cur_pid" &&
			kill -0 "$new_pid" &&
			kill -QUIT "$cur_pid"
	then
		n=$TIMEOUT
		while kill -0 "$cur_pid" 2>/dev/null && test $n -ge 0
		do
			printf '.' && sleep 1 && n=$(( $n - 1 ))
		done
		echo

		if test $n -lt 0 && kill -0 "$cur_pid" 2>/dev/null
		then
			echo >&2 "$cur_pid still running after $TIMEOUT seconds"
			exit 1
		fi
		exit 0
	fi
	echo >&2 "Couldn't upgrade, starting '$CMD' instead"
	$CMD
	;;
reopen-logs)
	sig USR1
	;;
*)
	echo >&2 "Usage: $0 <start|stop|restart|upgrade|force-stop|reopen-logs>"
	exit 1
	;;
esac
