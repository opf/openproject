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

module Workflows
  class IndexController < ApplicationController
    include ::PaginationHelper
    include OpTurbo::ComponentStream

    layout "admin"

    before_action :require_admin
    before_action :load_query

    menu_item :workflows

    helper_method :results_component, :sub_header_component

    def index
      respond_to do |format|
        format.html
        format.turbo_stream do
          update_via_turbo_stream(component: results_component)
          respond_with_turbo_streams
        end
      end
    end

    def projects_tree
      render WorkPackageTypes::NamedReferences::Index::ProjectsTreeComponent.new(
        nodes: ::Project.build_projects_hierarchy(candidate_projects),
        builder: ActionView::Helpers::FormBuilder.new("", nil, view_context, {}),
        form_name: params[:name],
        checked_ids: Array(params[:checked_ids])
      ),
             layout: false
    end

    private

    def model_class = ::Workflow

    def load_query
      @query = ::Queries::Workflows::WorkflowQuery.new

      @query.where(:name, "~", [name_term]) if name_term.present?
      @query.where(:type_id, "=", filtered_type_ids) if filtered_type_ids.any?
      @query.where(:project_id, "=", filtered_project_ids) if filtered_project_ids.any?

      @query
    end

    def name_term = @name_term ||= values_for(::Queries::Workflows::Filters::NameFilter.key).first.to_s.strip

    def filtered_type_ids = @filtered_type_ids ||= values_for(::Queries::Workflows::Filters::TypeFilter.key)

    def filtered_project_ids = @filtered_project_ids ||= values_for(::Queries::Workflows::Filters::ProjectFilter.key)

    def values_for(filter_key)
      requested_filters
        .select { |filter| filter[:attribute].to_s == filter_key.to_s }
        .flat_map { |filter| Array(filter[:values]).map(&:to_s) }
        .compact_blank
    end

    def requested_filters
      return @requested_filters if defined?(@requested_filters)

      @requested_filters = params[:filters].blank? ? [] : Array(::Queries::ParamsParser.parse(params)[:filters])
    rescue StandardError
      @requested_filters = []
    end

    def filtered? = requested_filters.any?

    def results_component
      table = Index::TableComponent.new(records: workflows,
                                        variants: workflow_variants,
                                        role_counts: workflow_role_counts,
                                        filtered: filtered?)

      WorkPackageTypes::NamedReferences::Index::ResultsComponent.new(table:)
    end

    def sub_header_component
      WorkPackageTypes::NamedReferences::Index::SubHeaderComponent.new(query: @query, model_class:)
    end

    def workflows
      @workflows ||= begin
        page = @query.results.includes(:project).page(page_param).per_page(per_page_param)
        page = page.page(page.total_pages) if page.out_of_bounds? && page.total_pages.positive?
        page
      end
    end

    def workflow_variants
      @workflow_variants ||= TypeVariant
                               .where(workflow_id: workflow_ids)
                               .includes(:type, :projects)
                               .joins(:type)
                               .merge(::Type.order(:position))
                               .in_display_order
                               .group_by(&:workflow_id)
    end

    def workflow_role_counts
      @workflow_role_counts ||= ::Workflows::StatusTransition
                                  .where(workflow_id: workflow_ids)
                                  .distinct
                                  .group(:workflow_id)
                                  .count(:role_id)
    end

    def workflow_ids = @workflow_ids ||= workflows.map(&:id)

    def candidate_projects
      scope = ::Project.order(:lft)
      return scope.to_a if tree_term.blank?

      matching = scope.where("LOWER(projects.name) LIKE LOWER(?)", "%#{sanitized_tree_term}%")
      (matching.to_a + ancestors_of(matching)).uniq(&:id).sort_by(&:lft)
    end

    def ancestors_of(projects)
      return [] if projects.empty?

      ::Project.where(
        "EXISTS (SELECT 1 FROM projects descendants WHERE descendants.id IN (:ids) " \
        "AND projects.lft < descendants.lft AND projects.rgt > descendants.rgt)",
        ids: projects.map(&:id)
      ).to_a
    end

    def tree_term = params[:query].to_s.strip

    def sanitized_tree_term = ActiveRecord::Base.sanitize_sql_like(tree_term)
  end
end
