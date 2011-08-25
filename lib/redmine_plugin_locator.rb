class RedminePluginLocator < Rails::Plugin::FileSystemLocator
  def initialize(initializer)
    super
    @@instance = self
  end

  def self.instance
    @@instance
  end

  # This locator is not meant for loading plugins
  # The plugin loading is done by the default rails locator, this one is
  # only for querying available plugins easily
  def plugins(for_loading = true)
    return [] if for_loading
    super()
  end

  def has_plugin?(name)
    plugins(false).collect(&:name).include? name.to_s
  end
end
