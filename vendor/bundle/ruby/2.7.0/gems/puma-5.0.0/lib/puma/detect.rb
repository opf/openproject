# frozen_string_literal: true

module Puma
  # at present, MiniSSL::Engine is only defined in extension code, not in minissl.rb
  HAS_SSL = const_defined?(:MiniSSL, false) && MiniSSL.const_defined?(:Engine, false)

  def self.ssl?
    HAS_SSL
  end

  IS_JRUBY = defined?(JRUBY_VERSION)

  def self.jruby?
    IS_JRUBY
  end

  IS_WINDOWS = RUBY_PLATFORM =~ /mswin|ming|cygwin/

  def self.windows?
    IS_WINDOWS
  end

  # @version 5.0.0
  def self.mri?
    RUBY_ENGINE == 'ruby' || RUBY_ENGINE.nil?
  end

  # @version 5.0.0
  def self.forkable?
    ::Process.respond_to?(:fork)
  end
end
