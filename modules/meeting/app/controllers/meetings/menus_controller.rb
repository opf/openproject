# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
# See COPYRIGHT and LICENSE files for more details.
# ++
module Meetings
  class MenusController < ApplicationController
    before_action :load_and_authorize_in_optional_project

    def show
      @submenu_menu_items = ::Meetings::Menu.new(project: @project, params:).menu_items
      @create_btn_options = if @project.present? && User.current.allowed_in_project?(:create_meetings, @project)
                              { href: new_project_meeting_path(@project), module_key: "meeting" }
                            elsif @project.nil? && User.current.allowed_in_any_project?(:create_meetings)
                              { href: new_meeting_path, module_key: "meeting" }
                            end

      render layout: nil
    end
  end
end
