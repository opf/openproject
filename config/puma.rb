# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma.
#
threads_min_count = ENV.fetch("RAILS_MIN_THREADS") { 4 }
threads_max_count = ENV.fetch("RAILS_MAX_THREADS") { 16 }
threads threads_min_count, threads_max_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch("OPENPROJECT_WEB_WORKERS") { 1 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app! if ENV["RAILS_ENV"] == 'production'

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart unless ENV["RAILS_ENV"] == 'production'
