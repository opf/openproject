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
  # Where a type is administered from. The same tab components serve global administration
  # and a project's own settings, and they ask this instead of naming a route.
  #
  # Which one you get depends on where you are, not on what the type is: an administrator
  # browsing /types configures a project-owned variant through the admin routes, while a
  # project administrator configures that same variant through their project's.
  class TypeRoutes
    include Rails.application.routes.url_helpers

    def self.for(type, project: nil)
      project ? ProjectScoped.new(type, project) : Global.new(type)
    end

    def initialize(type)
      @type = type
    end

    attr_reader :type

    class Global < TypeRoutes
      def breadcrumb_root_items
        [{ href: admin_index_path, text: I18n.t("label_administration") },
         { href: admin_settings_work_packages_general_path, text: I18n.t(:label_work_package_plural) },
         { href: types_path, text: I18n.t(:label_type_plural) }]
      end

      def parent_details = edit_type_details_path(type_id: type.parent_id)

      def index = types_path
      def details = edit_type_details_path(type_id: type.id)
      def details_submit = type_details_path(type_id: type.id)
      def defaults = edit_type_defaults_path(type)
      def defaults_submit = type_defaults_path(type_id: type.id)
      def form_configuration = edit_type_form_configuration_path(type)
      def workflow(**) = edit_type_workflow_path(type, **)
      def project_attributes = edit_type_project_attributes_path(type)
      def pdf_export = edit_type_pdf_export_template_index_path(type_id: type.id)
      def projects = edit_type_projects_path(type)

      def wizard(step: nil) = type_creation_wizard_path(type, step:)
      def wizard_submit = creation_wizard_types_path

      def workflow_matrix(**) = type_workflow_matrix_path(type, **)
      def workflow_matrix_status_dialog(**) = status_dialog_type_workflow_matrix_path(type, **)
      def workflow_matrix_confirm_statuses(**) = confirm_statuses_type_workflow_matrix_path(type, **)
      def workflow_copy(**) = new_type_workflow_copy_path(type, **)
      def form_configuration_reset_dialog = reset_dialog_type_form_configuration_path(type)
      def form_configuration_groups = type_form_configuration_groups_path(type)
      def add_form_configuration_group = add_group_type_form_configuration_groups_path(type)
      def form_configuration_group(key) = type_form_configuration_group_path(type, key)
      def edit_form_configuration_group(key) = edit_type_form_configuration_group_path(type, key)
      def move_form_configuration_group(key) = move_type_form_configuration_group_path(type, key)
      def drop_form_configuration_group(key) = drop_type_form_configuration_group_path(type, key)
      def cancel_edit_form_configuration_group(key) = cancel_edit_type_form_configuration_group_path(type, key)
      def update_query_form_configuration_group(key) = update_query_type_form_configuration_group_path(type, key)
      def drop_form_configuration_row(key) = drop_type_form_configuration_row_path(type, key)
      def move_form_configuration_row(key) = move_type_form_configuration_row_path(type, key)

      def toggle_project_attribute = toggle_type_project_attributes_path(type)
      def enable_all_project_attributes = enable_all_of_section_type_project_attributes_path(type)
      def disable_all_project_attributes = disable_all_of_section_type_project_attributes_path(type)

      def toggle_pdf_template(id) = toggle_type_pdf_export_template_path(type_id: type.id, id:)
      def drop_pdf_template(id) = drop_type_pdf_export_template_path(type_id: type.id, id:)
      def enable_all_pdf_templates = enable_all_type_pdf_export_template_index_path(type_id: type.id)
      def disable_all_pdf_templates = disable_all_type_pdf_export_template_index_path(type_id: type.id)
      def update_artefact_export = update_artefact_export_type_pdf_export_template_index_path(type_id: type.id)

      def configuration_link_dialog(aspect) = type_configuration_link_dialog_path(type_id: type.id, aspect:)
      def configuration_copy_dialog(aspect) = type_configuration_copy_dialog_path(type_id: type.id, aspect:)
      def source_details(source) = edit_type_details_path(type_id: source.id)

      def configuration_independence_dialog(aspect)
        type_configuration_independence_dialog_path(type_id: type.id, aspect:)
      end
    end

    class ProjectScoped < TypeRoutes
      def initialize(type, project)
        super(type)

        @project = project
      end

      attr_reader :project

      def breadcrumb_root_items
        [{ href: project_settings_general_path(project), text: I18n.t("label_project_settings") },
         { href: project_settings_work_packages_path(project), text: I18n.t(:label_work_package_plural) },
         { href: index, text: I18n.t(:label_type_plural) }]
      end

      # The parent is a global type, administered somewhere this user cannot go, so it
      # names the family without pretending to be a way there.
      def parent_details = nil

      def index = project_settings_work_packages_types_path(project)
      def details = edit_project_settings_work_packages_types_variant_details_path(project, type)
      def details_submit = project_settings_work_packages_types_variant_details_path(project, type)
      def defaults = edit_project_settings_work_packages_types_variant_defaults_path(project, type)
      def defaults_submit = project_settings_work_packages_types_variant_defaults_path(project, type)
      def workflow(**) = edit_project_settings_work_packages_types_variant_workflow_path(project, type, **)

      def form_configuration
        edit_project_settings_work_packages_types_variant_form_configuration_path(project, type)
      end

      def project_attributes
        edit_project_settings_work_packages_types_variant_project_attributes_path(project, type)
      end

      def pdf_export
        edit_project_settings_work_packages_types_variant_pdf_export_template_index_path(project, type)
      end

      # A project-owned variant is only usable in its owner, so there is nothing to
      # activate elsewhere and no tab to reach.
      def projects = nil

      def wizard(step: nil)
        project_settings_work_packages_types_variant_creation_wizard_path(project, type, step:)
      end

      def wizard_submit = creation_wizard_project_settings_work_packages_types_variants_path(project)

      def workflow_matrix(**)
        project_settings_work_packages_types_variant_workflow_matrix_path(project, type, **)
      end

      def workflow_matrix_status_dialog(**)
        status_dialog_project_settings_work_packages_types_variant_workflow_matrix_path(project, type, **)
      end

      def workflow_matrix_confirm_statuses(**)
        confirm_statuses_project_settings_work_packages_types_variant_workflow_matrix_path(project, type, **)
      end

      # Copying a workflow reaches across every type and role in the instance, which is
      # more than owning one variant grants.
      def workflow_copy(**) = nil

      def form_configuration_reset_dialog
        reset_dialog_project_settings_work_packages_types_variant_form_configuration_path(project, type)
      end

      def form_configuration_groups
        project_settings_work_packages_types_variant_form_configuration_groups_path(project, type)
      end

      def add_form_configuration_group
        add_group_project_settings_work_packages_types_variant_form_configuration_groups_path(project, type)
      end

      def form_configuration_group(key)
        project_settings_work_packages_types_variant_form_configuration_group_path(project, type, key)
      end

      def edit_form_configuration_group(key)
        edit_project_settings_work_packages_types_variant_form_configuration_group_path(project, type, key)
      end

      def move_form_configuration_group(key)
        move_project_settings_work_packages_types_variant_form_configuration_group_path(project, type, key)
      end

      def drop_form_configuration_group(key)
        drop_project_settings_work_packages_types_variant_form_configuration_group_path(project, type, key)
      end

      def cancel_edit_form_configuration_group(key)
        cancel_edit_project_settings_work_packages_types_variant_form_configuration_group_path(project, type, key)
      end

      def update_query_form_configuration_group(key)
        update_query_project_settings_work_packages_types_variant_form_configuration_group_path(project, type, key)
      end

      def drop_form_configuration_row(key)
        drop_project_settings_work_packages_types_variant_form_configuration_row_path(project, type, key)
      end

      def move_form_configuration_row(key)
        move_project_settings_work_packages_types_variant_form_configuration_row_path(project, type, key)
      end

      def toggle_project_attribute
        toggle_project_settings_work_packages_types_variant_project_attributes_path(project, type)
      end

      def enable_all_project_attributes
        enable_all_of_section_project_settings_work_packages_types_variant_project_attributes_path(project, type)
      end

      def disable_all_project_attributes
        disable_all_of_section_project_settings_work_packages_types_variant_project_attributes_path(project, type)
      end

      def toggle_pdf_template(id)
        toggle_project_settings_work_packages_types_variant_pdf_export_template_path(project, type, id)
      end

      def drop_pdf_template(id)
        drop_project_settings_work_packages_types_variant_pdf_export_template_path(project, type, id)
      end

      def enable_all_pdf_templates
        enable_all_project_settings_work_packages_types_variant_pdf_export_template_index_path(project, type)
      end

      def disable_all_pdf_templates
        disable_all_project_settings_work_packages_types_variant_pdf_export_template_index_path(project, type)
      end

      def update_artefact_export
        update_artefact_export_project_settings_work_packages_types_variant_pdf_export_template_index_path(project, type)
      end

      # Reuse mode is still configured from administration only. Rather than render buttons
      # that would refuse the project administrator, the banner states the mode and stops.
      def configuration_link_dialog(_aspect) = nil
      def configuration_copy_dialog(_aspect) = nil
      def configuration_independence_dialog(_aspect) = nil

      # The source is a global type or another of this project's variants; either way its
      # own configuration screen is in administration.
      def source_details(_source) = nil
    end
  end
end
