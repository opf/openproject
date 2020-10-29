require "integration/band_representer"
require 'sinatra/runner'

class ServerRunner < Sinatra::Runner
  def app_file
    File.expand_path("../server.rb", __FILE__)
  end

  def command
    "bundle exec ruby #{app_file} -p #{port} -e production"
  end

  def ping_path # to be overwritten
    '/ping'
  end
end

class SslServerRunner < ServerRunner
  def command
    "bundle exec ruby #{File.expand_path("../ssl_server.rb", __FILE__)}"
  end

  def port
    8443
  end

  def protocol
    "https"
  end
end

begin
  runner = ServerRunner.new
  runner.run

  ssl_runner = SslServerRunner.new
  ssl_runner.run

  Minitest.after_run do
    runner.kill
    ssl_runner.kill
  end
rescue Exception => e
  runner.kill
  ssl_runner.kill

  raise e
end
