# frozen_string_literal: true

# Standard libraries
require 'socket'
require 'tempfile'
require 'time'
require 'etc'
require 'uri'
require 'stringio'

require 'thread'

require_relative 'puma/puma_http11'
require_relative 'puma/detect'

module Puma
  autoload :Const, 'puma/const'
  autoload :Server, 'puma/server'
  autoload :Launcher, 'puma/launcher'

  def self.stats_object=(val)
    @get_stats = val
  end

  def self.stats
    require 'json'
    @get_stats.stats.to_json
  end

  # @version 5.0.0
  def self.stats_hash
    @get_stats.stats
  end

  # Thread name is new in Ruby 2.3
  def self.set_thread_name(name)
    return unless Thread.current.respond_to?(:name=)
    Thread.current.name = "puma #{name}"
  end

  unless HAS_SSL
    module MiniSSL
      # this class is defined so that it exists when Puma is compiled
      # without ssl support, as Server and Reactor use it in rescue statements.
      class SSLError < StandardError ; end
    end
  end
end
