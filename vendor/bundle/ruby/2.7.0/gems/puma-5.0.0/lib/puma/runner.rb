# frozen_string_literal: true

require 'puma/server'
require 'puma/const'

module Puma
  # Generic class that is used by `Puma::Cluster` and `Puma::Single` to
  # serve requests. This class spawns a new instance of `Puma::Server` via
  # a call to `start_server`.
  class Runner
    def initialize(cli, events)
      @launcher = cli
      @events = events
      @options = cli.options
      @app = nil
      @control = nil
      @started_at = Time.now
    end

    def development?
      @options[:environment] == "development"
    end

    def test?
      @options[:environment] == "test"
    end

    def log(str)
      @events.log str
    end

    # @version 5.0.0
    def stop_control
      @control.stop(true) if @control
    end

    def error(str)
      @events.error str
    end

    def debug(str)
      @events.log "- #{str}" if @options[:debug]
    end

    def start_control
      str = @options[:control_url]
      return unless str

      require 'puma/app/status'

      if token = @options[:control_auth_token]
        token = nil if token.empty? || token == 'none'
      end

      app = Puma::App::Status.new @launcher, token

      control = Puma::Server.new app, @launcher.events
      control.min_threads = 0
      control.max_threads = 1

      control.binder.parse [str], self, 'Starting control server'

      control.run
      @control = control
    end

    # @version 5.0.0
    def close_control_listeners
      @control.binder.close_listeners if @control
    end

    def ruby_engine
      if !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby"
        "ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      else
        if defined?(RUBY_ENGINE_VERSION)
          "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} - ruby #{RUBY_VERSION}"
        else
          "#{RUBY_ENGINE} #{RUBY_VERSION}"
        end
      end
    end

    def output_header(mode)
      min_t = @options[:min_threads]
      max_t = @options[:max_threads]

      log "Puma starting in #{mode} mode..."
      log "* Version #{Puma::Const::PUMA_VERSION} (#{ruby_engine}), codename: #{Puma::Const::CODE_NAME}"
      log "* Min threads: #{min_t}, max threads: #{max_t}"
      log "* Environment: #{ENV['RACK_ENV']}"
    end

    def redirected_io?
      @options[:redirect_stdout] || @options[:redirect_stderr]
    end

    def redirect_io
      stdout = @options[:redirect_stdout]
      stderr = @options[:redirect_stderr]
      append = @options[:redirect_append]

      if stdout
        unless Dir.exist?(File.dirname(stdout))
          raise "Cannot redirect STDOUT to #{stdout}"
        end

        STDOUT.reopen stdout, (append ? "a" : "w")
        STDOUT.sync = true
        STDOUT.puts "=== puma startup: #{Time.now} ==="
      end

      if stderr
        unless Dir.exist?(File.dirname(stderr))
          raise "Cannot redirect STDERR to #{stderr}"
        end

        STDERR.reopen stderr, (append ? "a" : "w")
        STDERR.sync = true
        STDERR.puts "=== puma startup: #{Time.now} ==="
      end
    end

    def load_and_bind
      unless @launcher.config.app_configured?
        error "No application configured, nothing to run"
        exit 1
      end

      begin
        @app = @launcher.config.app
      rescue Exception => e
        log "! Unable to load application: #{e.class}: #{e.message}"
        raise e
      end

      @launcher.binder.parse @options[:binds], self
    end

    def app
      @app ||= @launcher.config.app
    end

    def start_server
      min_t = @options[:min_threads]
      max_t = @options[:max_threads]

      server = Puma::Server.new app, @launcher.events, @options
      server.min_threads = min_t
      server.max_threads = max_t
      server.inherit_binder @launcher.binder

      if @options[:early_hints]
        server.early_hints = true
      end

      unless development? || test?
        server.leak_stack_on_error = false
      end

      server
    end
  end
end
