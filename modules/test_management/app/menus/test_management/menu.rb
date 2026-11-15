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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  class Menu < Submenu
    # Data-driven: later stages append sections without rewriting Cases.
    SECTIONS = %w[cases].freeze

    CONTROLLER_SECTIONS = {
      "test_management/test_cases" => "cases"
    }.freeze

    def self.section_for(controller_path)
      CONTROLLER_SECTIONS[controller_path.to_s.delete_prefix("/")]
    end

    attr_reader :user

    def initialize(project:, params:, user: User.current)
      super(view_type: nil, project:, params:)
      @user = user
    end

    def vertical_navigation?
      TestManagement::ProjectSetting.for_project(project).vertical_navigation?
    end

    def horizontal_navigation?
      !vertical_navigation?
    end

    def current_section
      section = params[:section].to_s
      return section if SECTIONS.include?(section)

      self.class.section_for(params[:controller])
    end

    def menu_items
      return [] if horizontal_navigation?

      [menu_group(header: nil, children: section_items)]
    end

    def visible_sections
      SECTIONS.select { |section| visible?(section) }
    end

    def section_items
      visible_sections.map do |section|
        menu_item(title: I18n.t("test_management.menu.#{section}"),
                  href: section_path(section),
                  selected: section == current_section)
      end
    end

    def section_path(section)
      case section
      when "cases" then project_test_management_test_cases_path(project)
      end
    end

    def query_path(_query_params)
      project_test_management_test_cases_path(project)
    end

    private

    def visible?(section)
      return false unless project&.module_enabled?(:test_management)

      case section
      when "cases" then allowed?("test_management/test_cases", :index)
      else false
      end
    end

    def allowed?(controller, action)
      user.allowed_in_project?({ controller:, action: }, project)
    end
  end
end
