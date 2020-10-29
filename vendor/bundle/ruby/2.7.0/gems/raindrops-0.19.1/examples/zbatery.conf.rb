# Used for running Raindrops::Watcher, which requires a multi-threaded
# Rack server capable of streaming a response.  Threads must be used,
# so any multi-threaded Rack server may be used.
# zbatery was recommended in the past, but it is abandoned
# <http://zbatery.bogomip.org/>.
# yahns may work as an alternative (see yahns.conf.rb in this dir)
Rainbows! do
  use :ThreadSpawn
end
log_dir = "/var/log/zbatery"
if File.writable?(log_dir) && File.directory?(log_dir)
  stderr_path "#{log_dir}/raindrops-demo.stderr.log"
  stdout_path "#{log_dir}/raindrops-demo.stdout.log"
  listen "/tmp/.r"
  pid "/tmp/.raindrops.pid"
end
