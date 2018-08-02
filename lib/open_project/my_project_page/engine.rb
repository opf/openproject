#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require 'open_project/plugins'

require 'rails/engine'
require 'open_project/my_project_page/plugin_blocks'

module OpenProject::MyProjectPage
  class Engine < ::Rails::Engine
    engine_name :openproject_my_project_page

    include OpenProject::Plugins::ActsAsOpEngine

    view_actions = %i(index)
    edit_actions = %i(page_layout add_block save_changes update_custom_element render_attachments destroy_attachment)

    register 'openproject-my_project_page',
             author_url: 'http://finn.de',
             requires_openproject: '>= 4.0.0' do

      project_module :my_project_page do
        view_actions.each do |action|
          Redmine::AccessControl.permission(:view_project).actions << "my_projects_overviews/#{action}"
        end

        edit_actions.each do |action|
          Redmine::AccessControl.permission(:edit_project).actions << "my_projects_overviews/#{action}"
        end
      end
    end

    # Add paths to satisfy AttachableRespresenter interface
    add_api_path :overview do |id|
      "#{root}/overviews/#{id}"
    end

    add_api_path :my_projects_overview do |id|
      "#{root}/my_projects_overviews/#{id}"
    end

    add_api_path :attachments_by_overview do |id|
      "#{my_projects_overview(id)}/attachments"
    end

    add_api_path :attachments_by_my_projects_overview do |id|
      "#{overview(id)}/attachments"
    end


    patch_with_namespace :OpenProject, :TextFormatting, :Formats, :Markdown, :TextileConverter

    assets %w(my_project_page/my_projects_overview.css)
  end
end
