# frozen_string_literal: true

require 'shellwords'
require 'English'

# Core library that sends notices.
# See: https://github.com/airbrake/airbrake-ruby
require 'airbrake-ruby'

require 'airbrake/version'

# Automatically load needed files for the environment the library is running in.
if defined?(Rack)
  require 'airbrake/rack'

  require 'airbrake/rails' if defined?(Rails)
end

require 'airbrake/rake' if defined?(Rake::Task)
require 'airbrake/resque' if defined?(Resque)
require 'airbrake/sidekiq' if defined?(Sidekiq)
require 'airbrake/shoryuken' if defined?(Shoryuken)
require 'airbrake/delayed_job' if defined?(Delayed)
require 'airbrake/sneakers' if defined?(Sneakers)

require 'airbrake/logger'

# Notify of unhandled exceptions, if there were any, but ignore SystemExit.
at_exit do
  Airbrake.notify_sync($ERROR_INFO) if $ERROR_INFO
  Airbrake.close
end
