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

module Grids
  class ProjectAttributeWidgets < Grids::WidgetComponent
    include OpTurbo::Streamable

    renders_many :widgets, Grids::Widgets::ProjectAttributeSection

    param :project

    def title
      ""
    end

    def render?
      current_user.allowed_in_project?(:view_project_attributes, @project)
    end

    # For each configured section, call the the `with_widget` slot
    def before_render
      available_project_attributes_grouped_by_section.each do |section, project_custom_fields|
        with_widget(section, project_custom_fields, @project)
      end
    end

    private

    def available_project_attributes_grouped_by_section
      @available_project_attributes_grouped_by_section ||=
        ProjectCustomFieldSection
          .with_available_fields_for(@project)
          .select { |section, _| section.shown_in_overview_main_area? }
    end
  end
end
