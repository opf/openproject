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
  # Links to a variant's configuration screens. +project+ is the scope the page is rendered in,
  # not the variant's owner: an administrator configures a project's variant in administration.
  #
  # Screens only administration offers take no project, as the project routes do not have them.
  #
  # The routes are resolved against the application's url helpers rather than the includer's,
  # so controllers, components and the editor contexts can all mix this in.
  module VariantRoutes
    def variant_settings_path(project, variant)
      variant_route(project, variant,
                    base: :type_settings_path,
                    named: :type_variant_settings_path,
                    project_scoped: :project_type_variant_settings_path)
    end

    def edit_variant_details_path(project, variant)
      variant_route(project, variant,
                    base: :edit_type_details_path,
                    named: :edit_type_variant_details_path,
                    project_scoped: :edit_project_type_variant_details_path)
    end

    def variant_details_path(project, variant)
      variant_route(project, variant,
                    base: :type_details_path,
                    named: :type_variant_details_path,
                    project_scoped: :project_type_variant_details_path)
    end

    def edit_variant_defaults_path(project, variant)
      variant_route(project, variant,
                    base: :edit_type_defaults_path,
                    named: :edit_type_variant_defaults_path,
                    project_scoped: :edit_project_type_variant_defaults_path)
    end

    def variant_defaults_path(project, variant)
      variant_route(project, variant,
                    base: :type_defaults_path,
                    named: :type_variant_defaults_path,
                    project_scoped: :project_type_variant_defaults_path)
    end

    def edit_variant_form_configuration_path(project, variant)
      variant_route(project, variant,
                    base: :edit_type_form_configuration_path,
                    named: :edit_type_variant_form_configuration_path,
                    project_scoped: :edit_project_type_variant_form_configuration_path)
    end

    def toggle_required_variant_form_configuration_row_path(project, variant, row_key)
      variant_route(project, variant,
                    base: :toggle_required_type_form_configuration_row_path,
                    named: :toggle_required_type_variant_form_configuration_row_path,
                    project_scoped: :toggle_required_project_type_variant_form_configuration_row_path,
                    row_key:)
    end

    def edit_variant_project_attributes_path(project, variant)
      variant_route(project, variant,
                    base: :edit_type_project_attributes_path,
                    named: :edit_type_variant_project_attributes_path,
                    project_scoped: :edit_project_type_variant_project_attributes_path)
    end

    def toggle_variant_project_attributes_path(project, variant, **)
      variant_route(project, variant,
                    base: :toggle_type_project_attributes_path,
                    named: :toggle_type_variant_project_attributes_path,
                    project_scoped: :toggle_project_type_variant_project_attributes_path,
                    **)
    end

    def enable_all_of_section_variant_project_attributes_path(project, variant, **)
      variant_route(project, variant,
                    base: :enable_all_of_section_type_project_attributes_path,
                    named: :enable_all_of_section_type_variant_project_attributes_path,
                    project_scoped: :enable_all_of_section_project_type_variant_project_attributes_path,
                    **)
    end

    def disable_all_of_section_variant_project_attributes_path(project, variant, **)
      variant_route(project, variant,
                    base: :disable_all_of_section_type_project_attributes_path,
                    named: :disable_all_of_section_type_variant_project_attributes_path,
                    project_scoped: :disable_all_of_section_project_type_variant_project_attributes_path,
                    **)
    end

    def variant_configuration_link_dialog_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_link_dialog_path,
                    named: :type_variant_configuration_link_dialog_path,
                    project_scoped: :project_type_variant_configuration_link_dialog_path,
                    aspect:)
    end

    def variant_configuration_link_switch_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_link_switch_path,
                    named: :type_variant_configuration_link_switch_path,
                    project_scoped: :project_type_variant_configuration_link_switch_path,
                    aspect:)
    end

    def variant_configuration_independence_dialog_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_independence_dialog_path,
                    named: :type_variant_configuration_independence_dialog_path,
                    project_scoped: :project_type_variant_configuration_independence_dialog_path,
                    aspect:)
    end

    def variant_configuration_independence_confirm_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_independence_confirm_path,
                    named: :type_variant_configuration_independence_confirm_path,
                    project_scoped: :project_type_variant_configuration_independence_confirm_path,
                    aspect:)
    end

    def variant_configuration_independence_switch_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_independence_switch_path,
                    named: :type_variant_configuration_independence_switch_path,
                    project_scoped: :project_type_variant_configuration_independence_switch_path,
                    aspect:)
    end

    def variant_configuration_copy_confirm_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_copy_confirm_path,
                    named: :type_variant_configuration_copy_confirm_path,
                    project_scoped: :project_type_variant_configuration_copy_confirm_path,
                    aspect:)
    end

    def variant_configuration_copy_copy_path(project, variant, aspect)
      variant_route(project, variant,
                    base: :type_configuration_copy_copy_path,
                    named: :type_variant_configuration_copy_copy_path,
                    project_scoped: :project_type_variant_configuration_copy_copy_path,
                    aspect:)
    end

    def variant_excluded_element_toggle_path(project, variant, aspect, **)
      variant_route(project, variant,
                    base: :type_excluded_element_toggle_path,
                    named: :type_variant_excluded_element_toggle_path,
                    project_scoped: :project_type_variant_excluded_element_toggle_path,
                    aspect:, **)
    end

    def edit_variant_workflow_path(project, variant, **)
      variant_route(project, variant,
                    base: :edit_type_workflow_path,
                    named: :edit_type_variant_workflow_path,
                    project_scoped: :edit_project_type_variant_workflow_path,
                    **)
    end

    def change_variant_workflow_path(project, variant, **)
      variant_route(project, variant,
                    base: :change_type_workflow_path,
                    named: :change_type_variant_workflow_path,
                    project_scoped: :change_project_type_variant_workflow_path,
                    **)
    end

    def start_variant_workflow_path(project, variant, **)
      variant_route(project, variant,
                    base: :start_type_workflow_path,
                    named: :start_type_variant_workflow_path,
                    project_scoped: :start_project_type_variant_workflow_path,
                    **)
    end

    def variant_workflow_matrix_path(project, variant, **)
      variant_route(project, variant,
                    base: :type_workflow_matrix_path,
                    named: :type_variant_workflow_matrix_path,
                    project_scoped: :project_type_variant_workflow_matrix_path,
                    **)
    end

    def status_dialog_variant_workflow_matrix_path(project, variant, **)
      variant_route(project, variant,
                    base: :status_dialog_type_workflow_matrix_path,
                    named: :status_dialog_type_variant_workflow_matrix_path,
                    project_scoped: :status_dialog_project_type_variant_workflow_matrix_path,
                    **)
    end

    def confirm_statuses_variant_workflow_matrix_path(project, variant, **)
      variant_route(project, variant,
                    base: :confirm_statuses_type_workflow_matrix_path,
                    named: :confirm_statuses_type_variant_workflow_matrix_path,
                    project_scoped: :confirm_statuses_project_type_variant_workflow_matrix_path,
                    **)
    end

    def new_variant_workflow_copy_path(project, variant, **)
      variant_route(project, variant,
                    base: :new_type_workflow_copy_path,
                    named: :new_type_variant_workflow_copy_path,
                    project_scoped: :new_project_type_variant_workflow_copy_path,
                    **)
    end

    def variant_workflow_copy_from_role_path(project, variant, **)
      variant_route(project, variant,
                    base: :type_workflow_copy_from_role_path,
                    named: :type_variant_workflow_copy_from_role_path,
                    project_scoped: :project_type_variant_workflow_copy_from_role_path,
                    **)
    end

    def edit_variant_pdf_export_template_index_path(project, variant)
      variant_route(project, variant,
                    base: :edit_type_pdf_export_template_index_path,
                    named: :edit_type_variant_pdf_export_template_index_path,
                    project_scoped: :edit_project_type_variant_pdf_export_template_index_path)
    end

    def enable_all_variant_pdf_export_template_index_path(project, variant)
      variant_route(project, variant,
                    base: :enable_all_type_pdf_export_template_index_path,
                    named: :enable_all_type_variant_pdf_export_template_index_path,
                    project_scoped: :enable_all_project_type_variant_pdf_export_template_index_path)
    end

    def disable_all_variant_pdf_export_template_index_path(project, variant)
      variant_route(project, variant,
                    base: :disable_all_type_pdf_export_template_index_path,
                    named: :disable_all_type_variant_pdf_export_template_index_path,
                    project_scoped: :disable_all_project_type_variant_pdf_export_template_index_path)
    end

    def update_artefact_export_variant_pdf_export_template_index_path(project, variant)
      variant_route(project, variant,
                    base: :update_artefact_export_type_pdf_export_template_index_path,
                    named: :update_artefact_export_type_variant_pdf_export_template_index_path,
                    project_scoped: :update_artefact_export_project_type_variant_pdf_export_template_index_path)
    end

    def toggle_variant_pdf_export_template_path(project, variant, template_id)
      variant_route(project, variant,
                    base: :toggle_type_pdf_export_template_path,
                    named: :toggle_type_variant_pdf_export_template_path,
                    project_scoped: :toggle_project_type_variant_pdf_export_template_path,
                    id: template_id)
    end

    def drop_variant_pdf_export_template_path(project, variant, template_id)
      variant_route(project, variant,
                    base: :drop_type_pdf_export_template_path,
                    named: :drop_type_variant_pdf_export_template_path,
                    project_scoped: :drop_project_type_variant_pdf_export_template_path,
                    id: template_id)
    end

    def edit_settings_variant_pdf_export_template_path(project, variant, template_id)
      variant_route(project, variant,
                    base: :edit_settings_type_pdf_export_template_path,
                    named: :edit_settings_type_variant_pdf_export_template_path,
                    project_scoped: :edit_settings_project_type_variant_pdf_export_template_path,
                    id: template_id)
    end

    def update_settings_variant_pdf_export_template_path(project, variant, template_id)
      variant_route(project, variant,
                    base: :update_settings_type_pdf_export_template_path,
                    named: :update_settings_type_variant_pdf_export_template_path,
                    project_scoped: :update_settings_project_type_variant_pdf_export_template_path,
                    id: template_id)
    end

    def variant_creation_wizard_path(project, variant, **)
      variant_route(project, variant,
                    base: :type_creation_wizard_path,
                    named: :type_variant_creation_wizard_path,
                    project_scoped: :project_type_variant_creation_wizard_path,
                    **)
    end

    # For the workflow and form configuration a variant references by name, whose screens share
    # their actions.
    def variant_reference_path(project, variant, model_class, action: nil, **)
      reference = model_class.model_name.singular_route_key.to_sym
      prefix, segments = reference_route_scope(project, variant)

      op_routes.polymorphic_path([*prefix, reference], action:, **segments, **)
    end

    def new_variant_creation_wizard_path(project, type, **)
      type_route(project, type,
                 administration: :new_creation_wizard_type_variants_path,
                 project_scoped: :new_creation_wizard_project_type_variants_path,
                 **)
    end

    def variants_creation_wizard_path(project, type, **)
      type_route(project, type,
                 administration: :creation_wizard_type_variants_path,
                 project_scoped: :creation_wizard_project_type_variants_path,
                 **)
    end

    def variant_path(project, variant, **)
      type_route(project, variant.type_id, variant,
                 administration: :type_variant_path,
                 project_scoped: :project_type_variant_path,
                 **)
    end

    def edit_variant_projects_path(variant)
      administration_variant_route(variant,
                                   base: :edit_type_projects_path,
                                   named: :edit_type_variant_projects_path)
    end

    def variant_projects_path(variant)
      administration_variant_route(variant,
                                   base: :type_projects_path,
                                   named: :type_variant_projects_path)
    end

    def enable_all_variant_projects_path(variant, **)
      administration_variant_route(variant,
                                   base: :enable_all_type_projects_path,
                                   named: :enable_all_type_variant_projects_path,
                                   **)
    end

    def new_link_variant_projects_path(variant)
      administration_variant_route(variant,
                                   base: :new_link_type_projects_path,
                                   named: :new_link_type_variant_projects_path)
    end

    def tree_variant_projects_path(variant, **)
      administration_variant_route(variant,
                                   base: :tree_type_projects_path,
                                   named: :tree_type_variant_projects_path,
                                   **)
    end

    def link_variant_projects_path(variant)
      administration_variant_route(variant,
                                   base: :link_type_projects_path,
                                   named: :link_type_variant_projects_path)
    end

    def unlink_variant_projects_path(variant, **)
      administration_variant_route(variant,
                                   base: :unlink_type_projects_path,
                                   named: :unlink_type_variant_projects_path,
                                   **)
    end

    def new_switch_variant_projects_path(variant, **)
      administration_variant_route(variant,
                                   base: :new_switch_type_projects_path,
                                   named: :new_switch_type_variant_projects_path,
                                   **)
    end

    def switch_variant_projects_path(variant, **)
      administration_variant_route(variant,
                                   base: :switch_type_projects_path,
                                   named: :switch_type_variant_projects_path,
                                   **)
    end

    def start_variant_form_configuration_path(variant, **)
      administration_variant_route(variant,
                                   base: :start_type_form_configuration_path,
                                   named: :start_type_variant_form_configuration_path,
                                   **)
    end

    def configure_dialog_variant_form_configuration_path(variant, **)
      administration_variant_route(variant,
                                   base: :configure_dialog_type_form_configuration_path,
                                   named: :configure_dialog_type_variant_form_configuration_path,
                                   **)
    end

    def configure_variant_form_configuration_path(variant, **)
      administration_variant_route(variant,
                                   base: :configure_type_form_configuration_path,
                                   named: :configure_type_variant_form_configuration_path,
                                   **)
    end

    def variant_form_configuration_path(variant, **)
      administration_variant_route(variant,
                                   base: :type_form_configuration_path,
                                   named: :type_variant_form_configuration_path,
                                   **)
    end

    def configure_dialog_variant_workflow_path(variant, **)
      administration_variant_route(variant,
                                   base: :configure_dialog_type_workflow_path,
                                   named: :configure_dialog_type_variant_workflow_path,
                                   **)
    end

    def configure_variant_workflow_path(variant, **)
      administration_variant_route(variant,
                                   base: :configure_type_workflow_path,
                                   named: :configure_type_variant_workflow_path,
                                   **)
    end

    def variant_workflow_path(variant, **)
      administration_variant_route(variant,
                                   base: :type_workflow_path,
                                   named: :type_variant_workflow_path,
                                   **)
    end

    private

    def variant_route(project, variant, base:, named:, project_scoped:, **)
      if project
        op_routes.public_send(project_scoped, project, variant.type_id, variant, **)
      else
        administration_variant_route(variant, base:, named:, **)
      end
    end

    def administration_variant_route(variant, base:, named:, **)
      if variant.default?
        op_routes.public_send(base, variant.type_id, **)
      else
        op_routes.public_send(named, variant.type_id, variant, **)
      end
    end

    def reference_route_scope(project, variant)
      if project
        [%i[project type variant], { project_id: project, type_id: variant.type_id, variant_id: variant }]
      elsif variant.default?
        [%i[type], { type_id: variant.type_id }]
      else
        [%i[type variant], { type_id: variant.type_id, variant_id: variant }]
      end
    end

    def type_route(project, *, administration:, project_scoped:, **)
      if project
        op_routes.public_send(project_scoped, project, *, **)
      else
        op_routes.public_send(administration, *, **)
      end
    end

    def op_routes = Rails.application.routes.url_helpers
  end
end
