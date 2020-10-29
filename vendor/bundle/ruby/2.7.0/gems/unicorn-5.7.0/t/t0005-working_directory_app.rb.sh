#!/bin/sh
. ./test-lib.sh

t_plan 4 "fooapp.rb inside alt working_directory"

t_begin "setup and start" && {
	unicorn_setup
	rm -rf $t_pfx.app
	mkdir $t_pfx.app

	cat > $t_pfx.app/fooapp.rb <<\EOF
class Fooapp
  def self.call(env)
    # Rack::Lint in 1.5.0 requires headers to be a hash
    h = [%w(Content-Type text/plain), %w(Content-Length 2)]
    h = Rack::Utils::HeaderHash.new(h)
    [ 200, h, %w(HI) ]
  end
end
EOF
	# the whole point of this exercise
	echo "working_directory '$t_pfx.app'" >> $unicorn_config
	cd /
	unicorn -D -c $unicorn_config -I. fooapp.rb
	unicorn_wait_start
}

t_begin "hit with curl" && {
	body=$(curl -sSf http://$listen/)
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "response body expected" && {
	test x"$body" = xHI
}

t_done
