# frozen_string_literal: true

#-- copyright
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
#++

module Header
  class ProjectSelectComponent < ApplicationComponent
    include OpenProject::StaticRouting::UrlHelpers

    delegate :logged?, to: :@current_user

    def initialize(current_project: nil, current_menu_item: nil, current_user: User.current)
      super()
      @current_project = current_project
      @current_user = current_user
      @current_menu_item = current_menu_item
    end

    def trigger_label
      @current_project&.name || t(".all_projects")
    end

    def tree_src
      frame_header_projects_path(
        current_project_id: @current_project&.id,
        jump: @current_menu_item.presence
      )
    end

    def can_create_projects?
      @current_user.allowed_globally?(:add_project)
    end
  end
end
