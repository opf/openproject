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

    register 'openproject-my_project_page',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 4.0.0' do

      project_module :my_project_page do
        Redmine::AccessControl.permission(:view_project).actions << "my_projects_overviews/index" <<
            "my_projects_overviews/show_all_members"
        Redmine::AccessControl.permission(:edit_project).actions << "my_projects_overviews/page_layout" <<
            "my_projects_overviews/add_block" <<
            "my_projects_overviews/remove_block" <<
            "my_projects_overviews/update_custom_element" <<
            "my_projects_overviews/order_blocks" <<
            "my_projects_overviews/destroy_attachment"
      end
    end

    assets %w(my_project_page/my_projects_overview.css my_project_page/my_project_page.js)
  end
end
