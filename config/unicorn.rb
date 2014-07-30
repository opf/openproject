worker_processes Integer(ENV["WEB_CONCURRENCY"] || 1)
timeout 15
preload_app false
