# This app is intended to test large HTTP requests with or without
# a fully-buffering reverse proxy such as nginx. Without a fully-buffering
# reverse proxy, unicorn will be unresponsive when client count exceeds
# worker_processes.

DOC = <<DOC
To demonstrate how bad unicorn is at slowly uploading clients:

  # in one terminal, start unicorn with one worker:
  unicorn -E none -l 127.0.0.1:8080 test/benchmark/readinput.ru

  # in a different terminal, upload 45M from multiple curl processes:
  dd if=/dev/zero bs=45M count=1 | curl -T- -HExpect: --limit-rate 1M \
     --trace-time -v http://127.0.0.1:8080/ &
  dd if=/dev/zero bs=45M count=1 | curl -T- -HExpect: --limit-rate 1M \
     --trace-time -v http://127.0.0.1:8080/ &
  wait

# The last client won't see a response until the first one is done uploading
# You also won't be able to make GET requests to view this documentation
# while clients are uploading.  You can also view the stderr debug output
# of unicorn (see logging code in #{__FILE__}).
DOC

run(lambda do |env|
  input = env['rack.input']
  buf = ''.b

  # default logger contains timestamps, rely on that so users can
  # see what the server is doing
  l = env['rack.logger']

  l.debug('BEGIN reading input ...') if l
  :nop while input.read(16384, buf)
  l.debug('DONE reading input ...') if l

  buf.clear
  [ 200, [ %W(Content-Length #{DOC.size}), %w(Content-Type text/plain) ],
    [ DOC ] ]
end)
