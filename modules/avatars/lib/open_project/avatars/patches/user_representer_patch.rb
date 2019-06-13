module OpenProject::Avatars::Patches
  module UserRepresenterPatch
    extend ActiveSupport::Concern

    included do
      ##
      # Dependencies required to cache users with avatars
      # When the plugin is loaded, depend on its settings
      def avatar_cache_dependencies
        [Setting.plugin_openproject_avatars, Setting.protocol]
      end
    end
  end
end
