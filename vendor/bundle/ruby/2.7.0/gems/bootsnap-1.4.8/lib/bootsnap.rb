# frozen_string_literal: true

require_relative('bootsnap/version')
require_relative('bootsnap/bundler')
require_relative('bootsnap/load_path_cache')
require_relative('bootsnap/compile_cache')

module Bootsnap
  InvalidConfiguration = Class.new(StandardError)

  def self.setup(
    cache_dir:,
    development_mode: true,
    load_path_cache: true,
    autoload_paths_cache: true,
    disable_trace: false,
    compile_cache_iseq: true,
    compile_cache_yaml: true
  )
    if autoload_paths_cache && !load_path_cache
      raise(InvalidConfiguration, "feature 'autoload_paths_cache' depends on feature 'load_path_cache'")
    end

    setup_disable_trace if disable_trace

    Bootsnap::LoadPathCache.setup(
      cache_path:       cache_dir + '/bootsnap-load-path-cache',
      development_mode: development_mode,
      active_support:   autoload_paths_cache
    ) if load_path_cache

    Bootsnap::CompileCache.setup(
      cache_dir: cache_dir + '/bootsnap-compile-cache',
      iseq: compile_cache_iseq,
      yaml: compile_cache_yaml
    )
  end

  def self.setup_disable_trace
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5.0')
      warn(
        "from #{caller_locations(1, 1)[0]}: The 'disable_trace' method is not allowed with this Ruby version. " \
        "current: #{RUBY_VERSION}, allowed version: < 2.5.0",
      )
    else
      RubyVM::InstructionSequence.compile_option = { trace_instruction: false }
    end
  end
end
