worker_processes Integer(ENV['WEB_CONCURRENCY'] || 1)
timeout Integer(ENV['WEB_TIMEOUT'] || 15)
preload_app false
