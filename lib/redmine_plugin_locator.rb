#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
