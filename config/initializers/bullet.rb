#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

if defined?(Bullet) && Rails.env.development?
  OpenProject::Application.configure do
    config.after_initialize do
      Bullet.enable = true
      # Bullet.alert = true
      Bullet.bullet_logger = true if File.directory?('log') # fails if run from an engine
      Bullet.console = true
      # Bullet.growl = true
      Bullet.rails_logger = true
    end
  end
end
