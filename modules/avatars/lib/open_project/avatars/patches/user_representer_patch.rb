module OpenProject::Avatars::Patches
  module UserRepresenterPatch
    def self.included(base)
      base.singleton_class.prepend ClassMethods
    end

    module ClassMethods
      ##
      # Dependencies required to cache users with avatars
      # When the plugin is loaded, depend on its settings
      def avatar_cache_dependencies
        [Setting.plugin_openproject_avatars, Setting.protocol]
      end
    end
  end
end