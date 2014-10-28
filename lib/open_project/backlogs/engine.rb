#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'open_project/plugins'

require 'acts_as_silent_list'

module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      { :default => { "story_types"  => nil,
                      "task_type"    => nil,
                      "card_spec"    => nil
      },
      :partial => 'shared/settings' }
    end

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-backlogs',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 4.0.0',
             :settings => settings do

      Redmine::AccessControl.permission(:edit_project).actions << "projects/project_done_statuses"
      Redmine::AccessControl.permission(:edit_project).actions << "projects/rebuild_positions"

      project_module :backlogs do
        # SYNTAX: permission :name_of_permission, { :controller_name => [:action1, :action2] }

        # Master backlog permissions
        permission :view_master_backlog, {
          :rb_master_backlogs  => :index,
          :rb_sprints          => [:index, :show],
          :rb_wikis            => :show,
          :rb_stories          => [:index, :show],
          :rb_queries          => :show,
          :rb_server_variables => :show,
          :rb_burndown_charts  => :show,
          :rb_export_card_configurations => [:index, :show]
        }

        permission :view_taskboards,     {
          :rb_taskboards       => :show,
          :rb_sprints          => :show,
          :rb_stories          => :show,
          :rb_tasks            => [:index, :show],
          :rb_impediments      => [:index, :show],
          :rb_wikis            => :show,
          :rb_server_variables => :show,
          :rb_burndown_charts  => :show,
          :rb_export_card_configurations => [:index, :show]
        }

        # Sprint permissions
        # :show_sprints and :list_sprints are implicit in :view_master_backlog permission
        permission :update_sprints,      {
          :rb_sprints => [:edit, :update],
          :rb_wikis   => [:edit, :update]
        }

        # Story permissions
        # :show_stories and :list_stories are implicit in :view_master_backlog permission
        permission :create_stories,         { :rb_stories => :create }
        permission :update_stories,         { :rb_stories => :update }

        # Task permissions
        # :show_tasks and :list_tasks are implicit in :view_sprints
        permission :create_tasks,           { :rb_tasks => [:new, :create]  }
        permission :update_tasks,           { :rb_tasks => [:edit, :update] }

        # Impediment permissions
        # :show_impediments and :list_impediments are implicit in :view_sprints
        permission :create_impediments,     { :rb_impediments => [:new, :create]  }
        permission :update_impediments,     { :rb_impediments => [:edit, :update] }
      end

      menu :project_menu,
        :backlogs,
        {:controller => '/rb_master_backlogs', :action => :index},
        :caption => :project_module_backlogs,
        :before => :calendar,
        :param => :project_id,
        :if => proc { not(User.current.respond_to?(:impaired?) and User.current.impaired?) },
        :html => {:class => 'icon2 icon-backlogs-icon'}
    end

    assets %w(
      backlogs/backlogs.css
      backlogs/backlogs.js
      backlogs/master_backlog.css
      backlogs/taskboard.css
      backlogs/jquery.flot/excanvas.js
      backlogs/burndown.js
      angular/openproject-backlogs-app.js
    )

    patches [:PermittedParams, :WorkPackage, :Status, :MyController, :Project,
      :ProjectsController, :ProjectsHelper, :Query, :User, :VersionsController, :Version]

    extend_api_response(:v3, :work_packages, :work_package) do
      property :story_points, exec_context: :decorator, if: -> (*) { represented.model.backlogs_enabled? }
      property :remaining_hours, exec_context: :decorator, if: -> (*) { represented.model.backlogs_enabled? }

      send(:define_method, :story_points) do
        represented.model.story_points
      end

      send(:define_method, :remaining_hours) do
        represented.model.remaining_hours
      end
    end

    config.to_prepare do
      if WorkPackage.const_defined? "SAFE_ATTRIBUTES"
        WorkPackage::SAFE_ATTRIBUTES << "story_points"
        WorkPackage::SAFE_ATTRIBUTES << "remaining_hours"
        WorkPackage::SAFE_ATTRIBUTES << "position"
      else
        WorkPackage.safe_attributes "story_points", "remaining_hours", "position"
      end
    end

    initializer "backlogs.register_hooks" do
      require "open_project/backlogs/hooks"
    end
  end
end
