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

module WorkPackageTypes
  class ProjectsTabController < BaseTabController
    include OpTurbo::ComponentStream
    include ProjectsTab::TableRefresh
    include ProjectsTab::RefusalMessages

    before_action :load_query, only: %i[edit update link unlink enable_all_projects]
    before_action :load_linked_project, only: %i[unlink]

    current_menu_item [:edit, :update] do
      :types
    end

    def edit
      respond_to do |format|
        format.html
        format.turbo_stream do
          update_via_turbo_stream(component: projects_table_component)
          respond_with_turbo_streams
        end
      end
    end

    def update
      result = sync_projects(desired_project_ids)

      if result.success?
        redirect_to edit_variant_projects_path(@variant), notice: I18n.t(:notice_successful_update)
      else
        flash.now[:error] = aggregate_refusal_message(result)
        render :edit, status: :unprocessable_entity
      end
    end

    def new_link
      respond_with_dialog ProjectsTab::AddDialogComponent.new(variant: @variant)
    end

    def tree
      render ProjectsTab::TreeComponent.new(variant: @variant,
                                            nodes: ::Project.build_projects_hierarchy(candidate_projects),
                                            builder: tree_form_builder,
                                            form_name: params[:name]),
             layout: false
    end

    def link
      projects = ::Project.where(id: selected_project_ids)
      return refuse_empty_selection if projects.empty?

      switching = switching_project_types(projects)
      if unconfirmed_switch?(switching)
        return ask_to_switch(switching, url: link_variant_projects_path(@variant), project_ids: projects.ids)
      end

      result = apply_to(projects)

      close_dialog_via_turbo_stream(ProjectsTab::AddFormComponent::DIALOG_ID)
      result.on_success { render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update)) }
      respond_to_bulk_change(result)
    end

    def unlink
      result = ::Projects::Types::RemoveService
                 .new(user: current_user, model: @linked_project)
                 .call(variant: @variant)

      result.on_success { refresh_projects }
      result.on_failure { render_error_flash_message_via_turbo_stream(message: removal_refusal_message(result)) }

      respond_to_with_turbo_streams(status: result)
    end

    def enable_all_projects
      if params[:value] == "1"
        enable_everywhere
      else
        respond_to_bulk_change(project_assignments.remove(@variant.projects))
      end
    end

    private

    def load_linked_project
      @linked_project = ::Project.find(params.expect(:project_id))
    end

    def applied_variant
      @applied_variant ||= @linked_project.type_variant(@type)
    end

    def sync_projects(desired)
      applying = @variant.projects.pluck(:id)

      apply_to(::Project.where(id: desired - applying))
        .merge!(project_assignments.remove(::Project.where(id: applying - desired)))
    end

    def apply_to(projects, into: new_aggregate)
      projects.find_each { |project| into.add_dependent!(add_or_switch(project)) }

      into
    end

    def add_or_switch(project)
      applied = applied_variant_of(project)

      if applied.nil?
        ::Projects::Types::AddService.new(user: current_user, model: project).call(variant: @variant)
      elsif applied == @variant
        ServiceResult.success(result: project)
      else
        ::Projects::Types::SwitchVariantService
          .new(user: current_user, model: project)
          .call(source: applied, target: @variant)
      end
    end

    def applied_variant_of(project)
      project.project_types.find_by(type_id: @type.id)&.variant
    end

    def new_aggregate = ServiceResult.success(result: @variant)

    def project_assignments = ProjectAssignments.new(user: current_user, variant: @variant)

    def refuse_empty_selection
      update_via_turbo_stream(
        component: ProjectsTab::AddFormComponent.new(
          variant: @variant,
          validation_message: I18n.t("types.edit.projects.add_dialog.no_projects_selected")
        ),
        status: :bad_request
      )
      respond_with_turbo_streams
    end

    def switching_project_types(projects)
      ::ProjectType
        .where(type_id: @type.id, project: projects)
        .where.not(variant: @variant)
        .joins(:project)
        .merge(::Project.order(:lft))
        .preload(:project, :variant)
    end

    def switch_confirmed? = params[:confirm_switch] == "1"

    def unconfirmed_switch?(switching) = switching.any? && !switch_confirmed?

    def ask_to_switch(switching, url:, project_ids: [])
      dialog_via_turbo_stream(
        component: ProjectsTab::SwitchConfirmDialogComponent.new(variant: @variant, switching:, url:, project_ids:)
      )
      respond_with_turbo_streams
    end

    def close_switch_dialog
      close_dialog_via_turbo_stream(ProjectsTab::SwitchConfirmDialogComponent::DIALOG_ID) if switch_confirmed?
    end

    def enable_everywhere
      projects = ::Project.where.not(id: @variant.projects.select(:id))
      switching = switching_project_types(projects)
      if unconfirmed_switch?(switching)
        return ask_to_switch(switching, url: enable_all_variant_projects_path(@variant, value: "1"))
      end

      respond_to_bulk_change(apply_to(projects))
    end

    def respond_to_bulk_change(result)
      close_switch_dialog
      refresh_projects
      result.on_failure { render_error_flash_message_via_turbo_stream(message: aggregate_refusal_message(result)) }

      respond_to_with_turbo_streams(status: result)
    end

    def tree_form_builder
      ActionView::Helpers::FormBuilder.new("", nil, view_context, {})
    end

    def candidate_projects
      scope = ::Project.order(:lft)
      return scope.to_a if filter_term.blank?

      matching = Queries::Projects::Filters::NameAndIdentifierFilter
                   .create!(operator: "~", values: [sanitized_filter_term])
                   .apply_to(scope)
      scope.self_and_ancestors_of(matching).to_a
    end

    def filter_term = params[:query].to_s.strip

    def sanitized_filter_term = ActiveRecord::Base.sanitize_sql_like(filter_term)

    def selected_project_ids
      ids = Array(params[ProjectsTab::AddFormComponent::FIELD_NAME]).filter_map { |node| node_id_from(node) }

      params[:include_sub_items] == "1" ? with_descendants(ids) : ids
    end

    def node_id_from(payload)
      JSON.parse(payload)["nodeId"].presence&.to_i
    rescue JSON::ParserError, TypeError
      nil
    end

    def with_descendants(project_ids)
      ::Project.where(id: project_ids).flat_map { |project| project.self_and_descendants.ids }.uniq
    end

    # TODO: once the input is correctly delivered, read params.expect(type: [:project_ids])
    # directly instead of parsing it out of a JSON string.
    def desired_project_ids
      @desired_project_ids ||=
        Array(JSON.parse(params.expect(type: [:project_ids])[:project_ids])).compact_blank.map(&:to_i)
    end

    def removal_refusal_message(result)
      return type_deactivation_error_message(applied_variant, project: @linked_project) if blocked?(@linked_project)

      "#{@linked_project.name}: #{result.errors.full_messages.to_sentence}"
    end

    def blocked?(project) = WorkPackage.exists?(type_id: @type.id, project_id: project.id)
  end
end
