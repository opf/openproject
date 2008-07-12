# This is only here to allow for backwards compability with Engines that
# have been implemented based on Engines for Rails 1.2. It is preferred that
# the plugin list be accessed via Engines.plugins.

module Rails
  # Returns the Engines::Plugin::List from Engines.plugins. It is preferable to
  # access Engines.plugins directly.
  def self.plugins
    Engines.plugins
  end
end
