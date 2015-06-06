#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

require 'open_project/plugins'

module OpenProject::Webhooks
  class Engine < ::Rails::Engine
    engine_name :openproject_webhooks

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-webhooks',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.0.0pre43'

    config.before_configuration do |app|
      # This is required for the routes to be loaded first as the routes should
      # be prepended so they take precedence over the core.
      app.config.paths['config/routes.rb'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end
  end
end
