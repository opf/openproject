module Engines
  class Plugin
    class FileSystemLocator < Rails::Plugin::FileSystemLocator
      def create_plugin(path)
        plugin = Engines::Plugin.new(path)
        plugin.valid? ? plugin : nil
      end        
    end
  end
end

