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
  class MenusController < ApplicationController
    helper TestManagement::TestCasesHelper

    before_action :find_project_by_project_id
    before_action :authorize

    def show
      menu = TestManagement::Menu.new(project: @project, params:)
      @sidebar_menu_items = menu.menu_items
      @current_section = menu.current_section
      load_folder_tree if show_folder_tree?
      render layout: nil
    end

    private

    def show_folder_tree?
      @current_section == "cases" && TestManagement::ProjectSetting.for_project(@project).sidebar_layout?
    end

    def load_folder_tree # rubocop:disable Metrics/AbcSize
      @show_folder_tree = true
      @suites = @project.tm_suites.ordered.to_a
      @suite_roots = @suites.select { |s| s.parent_id.nil? }
      @all_cases_count = @project.tm_test_cases.count
      @suite_counts = @project.tm_test_cases.group(:suite_id).count
      @current_suite_id = params[:suite_id]
      @current_suite = @suites.find { |suite| suite.id.to_s == @current_suite_id.to_s }
    end
  end
end
