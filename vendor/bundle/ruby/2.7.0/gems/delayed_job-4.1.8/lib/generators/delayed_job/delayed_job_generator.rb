require 'rails/generators/base'
require 'delayed/compatibility'

class DelayedJobGenerator < Rails::Generators::Base
  source_paths << File.join(File.dirname(__FILE__), 'templates')

  def create_executable_file
    template 'script', "#{Delayed::Compatibility.executable_prefix}/delayed_job"
    chmod "#{Delayed::Compatibility.executable_prefix}/delayed_job", 0o755
  end
end
