# frozen_string_literal: true
module Bootsnap
  module LoadPathCache
    module CoreExt
      def self.make_load_error(path)
        err = LoadError.new(+"cannot load such file -- #{path}")
        err.instance_variable_set(Bootsnap::LoadPathCache::ERROR_TAG_IVAR, true)
        err.define_singleton_method(:path) { path }
        err
      end
    end
  end
end

module Kernel
  module_function # rubocop:disable Style/ModuleFunction

  alias_method(:require_without_bootsnap, :require)

  # Note that require registers to $LOADED_FEATURES while load does not.
  def require_with_bootsnap_lfi(path, resolved = nil)
    Bootsnap::LoadPathCache.loaded_features_index.register(path, resolved) do
      require_without_bootsnap(resolved || path)
    end
  end

  def require(path)
    return false if Bootsnap::LoadPathCache.loaded_features_index.key?(path)

    if (resolved = Bootsnap::LoadPathCache.load_path_cache.find(path))
      return require_with_bootsnap_lfi(path, resolved)
    end

    raise(Bootsnap::LoadPathCache::CoreExt.make_load_error(path))
  rescue LoadError => e
    e.instance_variable_set(Bootsnap::LoadPathCache::ERROR_TAG_IVAR, true)
    raise(e)
  rescue Bootsnap::LoadPathCache::ReturnFalse
    false
  rescue Bootsnap::LoadPathCache::FallbackScan
    fallback = true
  ensure
    if fallback
      require_with_bootsnap_lfi(path)
    end
  end

  alias_method(:require_relative_without_bootsnap, :require_relative)
  def require_relative(path)
    realpath = Bootsnap::LoadPathCache.realpath_cache.call(
      caller_locations(1..1).first.absolute_path, path
    )
    require(realpath)
  end

  alias_method(:load_without_bootsnap, :load)
  def load(path, wrap = false)
    if (resolved = Bootsnap::LoadPathCache.load_path_cache.find(path))
      return load_without_bootsnap(resolved, wrap)
    end

    # load also allows relative paths from pwd even when not in $:
    if File.exist?(relative = File.expand_path(path).freeze)
      return load_without_bootsnap(relative, wrap)
    end

    raise(Bootsnap::LoadPathCache::CoreExt.make_load_error(path))
  rescue LoadError => e
    e.instance_variable_set(Bootsnap::LoadPathCache::ERROR_TAG_IVAR, true)
    raise(e)
  rescue Bootsnap::LoadPathCache::ReturnFalse
    false
  rescue Bootsnap::LoadPathCache::FallbackScan
    fallback = true
  ensure
    if fallback
      load_without_bootsnap(path, wrap)
    end
  end
end

class Module
  alias_method(:autoload_without_bootsnap, :autoload)
  def autoload(const, path)
    # NOTE: This may defeat LoadedFeaturesIndex, but it's not immediately
    # obvious how to make it work. This feels like a pretty niche case, unclear
    # if it will ever burn anyone.
    #
    # The challenge is that we don't control the point at which the entry gets
    # added to $LOADED_FEATURES and won't be able to hook that modification
    # since it's done in C-land.
    autoload_without_bootsnap(const, Bootsnap::LoadPathCache.load_path_cache.find(path) || path)
  rescue LoadError => e
    e.instance_variable_set(Bootsnap::LoadPathCache::ERROR_TAG_IVAR, true)
    raise(e)
  rescue Bootsnap::LoadPathCache::ReturnFalse
    false
  rescue Bootsnap::LoadPathCache::FallbackScan
    fallback = true
  ensure
    if fallback
      autoload_without_bootsnap(const, path)
    end
  end
end
