#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require 'rails/engine'

module OpenProject::Plugins
  class Engine < ::Rails::Engine

    engine_name :openproject_plugins

    require 'open_project/plugins/patch_registry'
    require 'open_project/plugins/load_dependency'
    require 'open_project/plugins/acts_as_op_engine'

    config.after_initialize do
      spec = Bundler.environment.specs['openproject-plugins'][0]

      Redmine::Plugin.register :openproject_plugins do
        name 'OpenProject Plugins'
        author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
        author_url spec.homepage
        url 'https://www.openproject.org/projects/plugins'
        description spec.description
        version spec.version

        requires_openproject ">= 3.0.0pre8"
      end
    end
  end
end
