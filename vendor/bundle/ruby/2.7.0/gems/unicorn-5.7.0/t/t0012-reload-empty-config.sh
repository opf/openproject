#!/bin/sh
. ./test-lib.sh
t_plan 9 "reloading unset config resets defaults"

t_begin "setup and start" && {
	unicorn_setup
	rtmpfiles unicorn_config_orig before_reload after_reload
	cat $unicorn_config > $unicorn_config_orig
	cat >> $unicorn_config <<EOF
logger Logger.new(STDOUT)
preload_app true
timeout 0x7fffffff
worker_processes 2
after_fork { |s,w| }
\$dump_cfg = lambda { |fp,srv|
  defaults = Unicorn::Configurator::DEFAULTS
  defaults.keys.map { |x| x.to_s }.sort.each do |key|
    next if key =~ %r{\Astd(?:err|out)_path\z}
    key = key.to_sym
    def_value = defaults[key]
    srv_value = srv.respond_to?(key) ? srv.__send__(key)
                                     : srv.instance_variable_get("@#{key}")
    fp << "#{key}|#{srv_value}|#{def_value}\\n"
  end
}
before_fork { |s,w|
  File.open("$before_reload", "a") { |fp| \$dump_cfg.call(fp, s) }
}
before_exec { |s| }
EOF
	unicorn -D -c $unicorn_config env.ru
	unicorn_wait_start
}

t_begin "ensure worker is started" && {
	curl -sSf http://$listen/ > $tmp
}

t_begin "replace config file with original(-ish)" && {
	grep -v ^pid < $unicorn_config_orig > $unicorn_config
	cat >> $unicorn_config <<EOF
before_fork { |s,w|
  File.open("$after_reload", "a") { |fp| \$dump_cfg.call(fp, s) }
}
EOF
}

t_begin "reload signal succeeds" && {
	kill -HUP $unicorn_pid
	while ! egrep '(done|error) reloading' $r_err >/dev/null
	do
		sleep 1
	done
	while ! grep reaped < $r_err >/dev/null
	do
		sleep 1
	done
	grep 'done reloading' $r_err >/dev/null
}

t_begin "ensure worker is started" && {
	curl -sSf http://$listen/ > $tmp
}

t_begin "pid file no longer exists" && {
	if test -f $pid
	then
		die "pid=$pid should not exist"
	fi
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && {
	check_stderr
}

t_begin "ensure reloading restored settings" && {
	awk < $after_reload -F'|' '
$1 != "before_fork" && $2 != $3 { print $0; exit(1) }
'
}

t_done
