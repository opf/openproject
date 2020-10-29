module Cell
  module Caching
    module Notifications
      def fetch_from_cache_for(key, options)
        ActiveSupport::Notifications.instrument('read_fragment.cells', key: key) do
          cache_store.fetch(key, options) do
            ActiveSupport::Notifications.instrument('write_fragment.cells', key: key) do
              yield
            end
          end
        end
      end
    end
  end
end
