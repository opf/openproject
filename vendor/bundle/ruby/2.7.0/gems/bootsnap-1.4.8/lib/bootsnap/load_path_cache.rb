# frozen_string_literal: true

module Bootsnap
  module LoadPathCache
    ReturnFalse = Class.new(StandardError)
    FallbackScan = Class.new(StandardError)

    DOT_RB = '.rb'
    DOT_SO = '.so'
    SLASH  = '/'

    # If a NameError happens several levels deep, don't re-handle it
    # all the way up the chain: mark it once and bubble it up without
    # more retries.
    ERROR_TAG_IVAR = :@__bootsnap_rescued

    DL_EXTENSIONS = ::RbConfig::CONFIG
      .values_at('DLEXT', 'DLEXT2')
      .reject { |ext| !ext || ext.empty? }
      .map    { |ext| ".#{ext}" }
      .freeze
    DLEXT = DL_EXTENSIONS[0]
    # This is nil on linux and darwin, but I think it's '.o' on some other
    # platform.  I'm not really sure which, but it seems better to replicate
    # ruby's semantics as faithfully as possible.
    DLEXT2 = DL_EXTENSIONS[1]

    CACHED_EXTENSIONS = DLEXT2 ? [DOT_RB, DLEXT, DLEXT2] : [DOT_RB, DLEXT]

    class << self
      attr_reader(:load_path_cache, :autoload_paths_cache,
        :loaded_features_index, :realpath_cache)

      def setup(cache_path:, development_mode:, active_support: true)
        unless supported?
          warn("[bootsnap/setup] Load path caching is not supported on this implementation of Ruby") if $VERBOSE
          return
        end

        store = Store.new(cache_path)

        @loaded_features_index = LoadedFeaturesIndex.new
        @realpath_cache = RealpathCache.new

        @load_path_cache = Cache.new(store, $LOAD_PATH, development_mode: development_mode)
        require_relative('load_path_cache/core_ext/kernel_require')
        require_relative('load_path_cache/core_ext/loaded_features')

        if active_support
          # this should happen after setting up the initial cache because it
          # loads a lot of code. It's better to do after +require+ is optimized.
          require('active_support/dependencies')
          @autoload_paths_cache = Cache.new(
            store,
            ::ActiveSupport::Dependencies.autoload_paths,
            development_mode: development_mode
          )
          require_relative('load_path_cache/core_ext/active_support')
        end
      end

      def supported?
        RUBY_ENGINE == 'ruby' &&
        RUBY_PLATFORM =~ /darwin|linux|bsd/
      end
    end
  end
end

if Bootsnap::LoadPathCache.supported?
  require_relative('load_path_cache/path_scanner')
  require_relative('load_path_cache/path')
  require_relative('load_path_cache/cache')
  require_relative('load_path_cache/store')
  require_relative('load_path_cache/change_observer')
  require_relative('load_path_cache/loaded_features_index')
  require_relative('load_path_cache/realpath_cache')
end
