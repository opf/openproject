# frozen_string_literal: true

module TestManagement
  # Lazy-loaded body of the Test management sidebar submenu (0018): the section links and, on
  # the Cases section with the "sidebar" folder tree layout, the compact folder tree.
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

    def load_folder_tree
      @show_folder_tree = true
      @suites = @project.tm_suites.ordered.to_a
      @suite_roots = @suites.select { |s| s.parent_id.nil? }
      @all_cases_count = @project.tm_test_cases.not_deleted.count
      @suite_counts = @project.tm_test_cases.not_deleted.group(:suite_id).count
      @deleted_cases_count = @project.tm_test_cases.deleted.count
      @current_suite_id = params[:suite_id]
      @current_suite = @suites.find { |suite| suite.id.to_s == @current_suite_id.to_s }
    end
  end
end
