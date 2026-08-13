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

module WorkPackageTypes
  class ProjectsTabController < BaseTabController
    include OpTurbo::ComponentStream
    include TypeDeactivationErrorMessage

    before_action :load_query, only: %i[edit update link unlink switch enable_all_projects]
    before_action :load_linked_project, only: %i[unlink new_switch switch]

    current_menu_item [:edit, :update] do
      :types
    end

    helper_method :enabled_everywhere?, :enable_all_label

    def edit; end

    def update
      result = sync_projects(desired_project_ids)

      if result.success?
        redirect_to edit_type_projects_path(**@variant.path_args), notice: I18n.t(:notice_successful_update)
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

      result = apply_to(projects)

      close_dialog_via_turbo_stream("##{ProjectsTab::AddFormComponent::DIALOG_ID}")
      refresh_table

      if result.success?
        render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
      else
        render_error_flash_message_via_turbo_stream(message: aggregate_refusal_message(result))
      end

      respond_to_with_turbo_streams(status: result)
    end

    def unlink
      result = ::Projects::Types::RemoveService
                 .new(user: current_user, model: @linked_project)
                 .call(variant: @variant)

      result.on_success { refresh_table }
      result.on_failure { render_error_flash_message_via_turbo_stream(message: removal_refusal_message(result)) }

      respond_to_with_turbo_streams(status: result)
    end

    def new_switch
      respond_with_dialog ::Projects::Settings::WorkPackages::Types::SwitchDialogComponent.new(
        project: @linked_project, source: @variant, url: switch_path
      )
    end

    def switch
      target = @type.variants.find_by(id: params[:target_id])
      result = ::Projects::Types::SwitchVariantService
                 .new(user: current_user, model: @linked_project)
                 .call(source: @variant, target:)

      result.on_success { on_switched(target) }
      result.on_failure { on_switch_refused(target, result) }

      respond_to_with_turbo_streams(status: result)
    end

    def enable_all_projects
      result = if params[:value] == "1"
                 apply_to(::Project.where.not(id: @variant.projects.select(:id)))
               else
                 remove_from(@variant.projects)
               end

      refresh_table
      result.on_failure { render_error_flash_message_via_turbo_stream(message: aggregate_refusal_message(result)) }

      respond_to_with_turbo_streams(status: result)
    end

    private

    def enabled_everywhere?
      return @enabled_everywhere unless @enabled_everywhere.nil?

      @enabled_everywhere = @variant.projects.count == ::Project.count
    end

    def enable_all_label
      enabled_everywhere? ? I18n.t("types.edit.projects.disable_all") : I18n.t("types.edit.projects.enable_all")
    end

    def load_query
      @query = ProjectQuery.new(name: "work-package-type-variant-projects-#{@variant.id}") do |query|
        query.where(:type_variant_id, "=", [@variant.id.to_s])
        query.select(:name)
        query.order("lft" => "asc")
      end
    end

    def load_linked_project
      @linked_project = ::Project.find(params.expect(:project_id))
    end

    def switch_path
      switch_type_projects_path(**@variant.path_args, project_id: @linked_project.id)
    end

    def sync_projects(desired)
      applying = @variant.projects.pluck(:id)

      new_aggregate.tap do |aggregated|
        apply_to(::Project.where(id: desired - applying), into: aggregated)
        remove_from(::Project.where(id: applying - desired), into: aggregated)
      end
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

    def remove_from(projects, into: new_aggregate)
      projects.find_each do |project|
        into.add_dependent!(::Projects::Types::RemoveService.new(user: current_user, model: project).call(variant: @variant))
      end

      into
    end

    def new_aggregate = ServiceResult.success(result: @variant)

    def on_switched(target)
      close_dialog_via_turbo_stream(
        "##{::Projects::Settings::WorkPackages::Types::SwitchDialogComponent::DIALOG_ID}"
      )
      refresh_table
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("projects.settings.types.switch_dialog.success", type: target.composite_name)
      )
    end

    def on_switch_refused(target, result)
      message = result.errors.messages_for(:types).first
      return if message.blank?

      update_via_turbo_stream(
        component: ::Projects::Settings::WorkPackages::Types::SwitchFormComponent.new(
          project: @linked_project,
          source: @variant,
          selected: target || @variant,
          validation_message: message,
          url: switch_path
        )
      )
    end

    def refresh_table
      update_via_turbo_stream(
        component: ProjectsTab::TableComponent.new(
          query: @query, params: params.merge(variant: @variant, url_for_action: :edit)
        )
      )
    end

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

    def tree_form_builder
      ActionView::Helpers::FormBuilder.new("", nil, view_context, {})
    end

    def candidate_projects
      scope = ::Project.order(:lft)
      return scope.to_a if filter_term.blank?

      matching = scope.where("LOWER(projects.name) LIKE LOWER(?)", "%#{sanitized_filter_term}%")
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

    def aggregate_refusal_message(result)
      refused = result.dependent_results.reject(&:success?)
      blocked = blocked_project_ids(refused.map { |failed| failed.result.id })

      return blocked_message(blocked) if blocked.any?

      refused.map { |failed| "#{failed.result.name}: #{failed.errors.full_messages.to_sentence}" }.to_sentence
    end

    def blocked_message(project_ids)
      helpers.join_flash_messages(type_deactivation_error_messages(@variant, project_ids:))
    end

    def removal_refusal_message(result)
      return type_deactivation_error_message(@variant, project: @linked_project) if blocked?(@linked_project)

      "#{@linked_project.name}: #{result.errors.full_messages.to_sentence}"
    end

    def blocked_project_ids(project_ids)
      WorkPackage.where(type_id: @type.id, project_id: project_ids).distinct.pluck(:project_id)
    end

    def blocked?(project) = WorkPackage.exists?(type_id: @type.id, project_id: project.id)
  end
end
