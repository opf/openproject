# frozen_string_literal: true
module Bootsnap
  module LoadPathCache
    module CoreExt
      module ActiveSupport
        def self.without_bootsnap_cache
          prev = Thread.current[:without_bootsnap_cache] || false
          Thread.current[:without_bootsnap_cache] = true
          yield
        ensure
          Thread.current[:without_bootsnap_cache] = prev
        end

        def self.allow_bootsnap_retry(allowed)
          prev = Thread.current[:without_bootsnap_retry] || false
          Thread.current[:without_bootsnap_retry] = !allowed
          yield
        ensure
          Thread.current[:without_bootsnap_retry] = prev
        end

        module ClassMethods
          def autoload_paths=(o)
            super
            Bootsnap::LoadPathCache.autoload_paths_cache.reinitialize(o)
          end

          def search_for_file(path)
            return super if Thread.current[:without_bootsnap_cache]
            begin
              Bootsnap::LoadPathCache.autoload_paths_cache.find(path)
            rescue Bootsnap::LoadPathCache::ReturnFalse
              nil # doesn't really apply here
            rescue Bootsnap::LoadPathCache::FallbackScan
              nil # doesn't really apply here
            end
          end

          def autoloadable_module?(path_suffix)
            Bootsnap::LoadPathCache.autoload_paths_cache.load_dir(path_suffix)
          end

          def remove_constant(const)
            CoreExt::ActiveSupport.without_bootsnap_cache { super }
          end

          def require_or_load(*)
            CoreExt::ActiveSupport.allow_bootsnap_retry(true) do
              super
            end
          end

          # If we can't find a constant using the patched implementation of
          # search_for_file, try again with the default implementation.
          #
          # These methods call search_for_file, and we want to modify its
          # behaviour.  The gymnastics here are a bit awkward, but it prevents
          # 200+ lines of monkeypatches.
          def load_missing_constant(from_mod, const_name)
            CoreExt::ActiveSupport.allow_bootsnap_retry(false) do
              super
            end
          rescue NameError => e
            raise(e) if e.instance_variable_defined?(Bootsnap::LoadPathCache::ERROR_TAG_IVAR)
            e.instance_variable_set(Bootsnap::LoadPathCache::ERROR_TAG_IVAR, true)

            # This function can end up called recursively, we only want to
            # retry at the top-level.
            raise(e) if Thread.current[:without_bootsnap_retry]
            # If we already had cache disabled, there's no use retrying
            raise(e) if Thread.current[:without_bootsnap_cache]
            # NoMethodError is a NameError, but we only want to handle actual
            # NameError instances.
            raise(e) unless e.class == NameError
            # We can only confidently handle cases when *this* constant fails
            # to load, not other constants referred to by it.
            raise(e) unless e.name == const_name
            # If the constant was actually loaded, something else went wrong?
            raise(e) if from_mod.const_defined?(const_name)
            CoreExt::ActiveSupport.without_bootsnap_cache { super }
          end

          # Signature has changed a few times over the years; easiest to not
          # reiterate it with version polymorphism here...
          def depend_on(*)
            super
          rescue LoadError => e
            raise(e) if e.instance_variable_defined?(Bootsnap::LoadPathCache::ERROR_TAG_IVAR)
            e.instance_variable_set(Bootsnap::LoadPathCache::ERROR_TAG_IVAR, true)

            # If we already had cache disabled, there's no use retrying
            raise(e) if Thread.current[:without_bootsnap_cache]
            CoreExt::ActiveSupport.without_bootsnap_cache { super }
          end
        end
      end
    end
  end
end

module ActiveSupport
  module Dependencies
    class << self
      prepend(Bootsnap::LoadPathCache::CoreExt::ActiveSupport::ClassMethods)
    end
  end
end
