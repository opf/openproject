#!/bin/sh
. ./test-lib.sh
t_plan 11 "parser error test"

t_begin "setup and startup" && {
	unicorn_setup
	unicorn -D env.ru -c $unicorn_config
	unicorn_wait_start
}

t_begin "send a bad request" && {
	(
		printf 'GET / HTTP/1/1\r\nHost: example.com\r\n\r\n'
		cat $fifo > $tmp &
		wait
		echo ok > $ok
	) | socat - TCP:$listen > $fifo
	test xok = x$(cat $ok)
}

dbgcat tmp

t_begin "response should be a 400" && {
	grep -F 'HTTP/1.1 400 Bad Request' $tmp
}

t_begin "send a huge Request URI (REQUEST_PATH > (12 * 1024))" && {
	rm -f $tmp
	cat $fifo > $tmp &
	(
		set -e
		trap 'echo ok > $ok' EXIT
		printf 'GET /'
		for i in $(awk </dev/null 'BEGIN{for(i=0;i<1024;i++) print i}')
		do
			printf '0123456789ab'
		done
		printf ' HTTP/1.1\r\nHost: example.com\r\n\r\n'
	) | socat - TCP:$listen > $fifo || :
	test xok = x$(cat $ok)
	wait
}

t_begin "response should be a 414 (REQUEST_PATH)" && {
	grep -F 'HTTP/1.1 414 ' $tmp
}

t_begin "send a huge Request URI (QUERY_STRING > (10 * 1024))" && {
	rm -f $tmp
	cat $fifo > $tmp &
	(
		set -e
		trap 'echo ok > $ok' EXIT
		printf 'GET /hello-world?a'
		for i in $(awk </dev/null 'BEGIN{for(i=0;i<1024;i++) print i}')
		do
			printf '0123456789'
		done
		printf ' HTTP/1.1\r\nHost: example.com\r\n\r\n'
	) | socat - TCP:$listen > $fifo || :
	test xok = x$(cat $ok)
	wait
}

t_begin "response should be a 414 (QUERY_STRING)" && {
	grep -F 'HTTP/1.1 414 ' $tmp
}

t_begin "send a huge Request URI (FRAGMENT > 1024)" && {
	rm -f $tmp
	cat $fifo > $tmp &
	(
		set -e
		trap 'echo ok > $ok' EXIT
		printf 'GET /hello-world#a'
		for i in $(awk </dev/null 'BEGIN{for(i=0;i<64;i++) print i}')
		do
			printf '0123456789abcdef'
		done
		printf ' HTTP/1.1\r\nHost: example.com\r\n\r\n'
	) | socat - TCP:$listen > $fifo || :
	test xok = x$(cat $ok)
	wait
}

t_begin "response should be a 414 (FRAGMENT)" && {
	grep -F 'HTTP/1.1 414 ' $tmp
}

t_begin "server stderr should be clean" && check_stderr

t_begin "term signal sent" && kill $unicorn_pid

t_done
