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

module Admin::Import::Jira::ImportRuns
  class SelectProjectsController < ApplicationController
    include OpTurbo::ComponentStream
    include ComponentStreams

    before_action :require_admin
    before_action :find_jira_and_jira_import

    PER_PAGE = 20

    def show
      respond_with_dialog(
        Admin::Import::Jira::ImportRuns::SelectProjects::ModalComponent.new(
          jira_import: @jira_import,
          list_header_component: project_list_header_component,
          list_component: project_list_component,
          list_footer_component: project_list_footer_component,
          selected_count: selected_ids.size
        )
      )
    end

    def update
      ids = selected_ids.map(&:to_s).compact_blank
      available = @jira_import.available&.dig("projects") || []

      projects = ids.filter_map do |id|
        project = available.find { |p| p["id"] == id }
        { "id" => id, "name" => project["name"], "key" => project["key"] } if project
      end

      @jira_import.update!(projects:)
      stream_wizard do
        close_dialog_via_turbo_stream("##{Admin::Import::Jira::ImportRuns::SelectProjects::ModalComponent::MODAL_ID}")
      end
    end

    def filter
      set_filter(params[:filter])
      respond_with_modal_components(with_footer: true)
    end

    def switch_page
      set_page(params[:page])
      respond_with_modal_components(with_footer: true)
    end

    def check_all
      visible_ids = filtered_projects.pluck("id")
      new_selections = (selected_ids + visible_ids).uniq
      set_selection_ids(new_selections)
      respond_with_modal_components
    end

    def uncheck_all
      visible_ids = filtered_projects.pluck("id")
      new_selections = selected_ids - visible_ids
      set_selection_ids(new_selections)
      respond_with_modal_components
    end

    def toggle
      project_id = params[:project_id].to_s
      new_selections = if selected_ids.include?(project_id)
                         selected_ids - [project_id]
                       else
                         selected_ids + [project_id]
                       end
      set_selection_ids(new_selections)
      respond_with_counter_component
    end

    private

    def find_jira_and_jira_import
      @jira = Import::Jira.find(params[:jira_id])
      @jira_import = Import::JiraImport.find(params[:run_id])
      init_session if action_name == "show"
    end

    def init_session
      session[:selected_ids] = @jira_import.project_ids
      session[:project_page] = 1
      session[:project_filter] = nil
    end

    def respond_with_modal_components(with_footer: false)
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: project_list_component,
            method: "morph"
          )
          update_via_turbo_stream(
            component: project_list_counter_component,
            method: "morph"
          )
          if with_footer
            update_via_turbo_stream(
              component: project_list_footer_component,
              method: "morph"
            )
          end
          render turbo_stream: resolve_turbo_streams
        end
      end
    end

    def respond_with_counter_component
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: project_list_counter_component,
            method: "morph"
          )
          render turbo_stream: resolve_turbo_streams
        end
      end
    end

    def set_page(page)
      session[:project_page] = page
    end

    def set_filter(filter)
      session[:project_filter] = filter.blank? ? nil : filter.to_s.strip
    end

    def set_selection_ids(new_selections)
      session[:selected_ids] = new_selections.map(&:to_s).compact_blank.uniq
    end

    def selected_ids
      session[:selected_ids] || []
    end

    def project_filter
      session[:project_filter]
    end

    def page
      [[(session[:project_page] || 1).to_i, 1].compact.max, total_pages].min
    end

    def total_pages
      (filtered_projects.size.to_f / PER_PAGE).ceil
    end

    def available_projects
      @jira_import.available&.dig("projects") || []
    end

    def filtered_projects
      return available_projects if project_filter.blank?

      query = project_filter.downcase
      available_projects.select do |project|
        project["name"].to_s.downcase.include?(query) ||
          project["key"].to_s.downcase.include?(query)
      end
    end

    def paginated_projects
      start_index = (page - 1) * PER_PAGE
      filtered_projects.slice(start_index, PER_PAGE) || []
    end

    def project_list_header_component
      Admin::Import::Jira::ImportRuns::SelectProjects::ListHeaderComponent.new(
        jira_import: @jira_import,
        filter: project_filter
      )
    end

    def project_list_component
      Admin::Import::Jira::ImportRuns::SelectProjects::ListComponent.new(
        jira_import: @jira_import,
        selected_ids: selected_ids,
        projects: paginated_projects
      )
    end

    def project_list_footer_component
      Admin::Import::Jira::ImportRuns::SelectProjects::ListFooterComponent.new(
        jira_import: @jira_import,
        page: page,
        total_pages: total_pages
      )
    end

    def project_list_counter_component
      count = selected_ids.count
      Admin::Import::Jira::ImportRuns::SelectProjects::ModalSubmitComponent.new(
        jira_import: @jira_import,
        count:
      )
    end
  end
end
