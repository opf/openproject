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
    include LoadsWorkflowQuery
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
      render Index::ProjectsTreeComponent.new(
        nodes: ::Project.build_projects_hierarchy(candidate_projects),
        builder: tree_form_builder,
        form_name: params[:name],
        checked_ids: Array(params[:checked_ids])
      ),
             layout: false
    end

    private

    def tree_form_builder
      ActionView::Helpers::FormBuilder.new("", nil, view_context, {})
    end

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
