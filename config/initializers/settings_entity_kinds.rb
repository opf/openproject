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

Settings::EntityKinds.draw do
  kind :types, menu_item: :types, scope: -> { Type.order(:position) }, url: ->(type) { edit_type_details_path(type) } do
    attribute :name, label: -> { Type.human_attribute_name(:name) }, field: "type[name]"
    attribute :color, label: -> { Color.model_name.human }, field: "type[color_id]"
    attribute :is_milestone, label: -> { Type.human_attribute_name(:is_milestone) }, field: "type[is_milestone]"
    attribute :is_in_roadmap, label: -> { Type.human_attribute_name(:is_in_roadmap) }, field: "type[is_in_roadmap]"
    attribute :allow_project_variants,
              label: -> { Type.human_attribute_name(:allow_project_variants) },
              field: "type[allow_project_variants]"
    attribute :default_description,
              label: :"types.edit.defaults.description.label",
              url: ->(type) { edit_type_defaults_path(type) },
              field: "work_package_types_forms_defaults_form_model[default_work_package_description]"
    attribute :subject_pattern,
              label: :"types.edit.defaults.automatically_generated_subjects.label",
              url: ->(type) { edit_type_defaults_path(type) },
              field: "work_package_types_forms_defaults_form_model[subject_configuration]"
    attribute :form_configuration,
              label: :"types.edit.form_configuration.tab",
              url: ->(type) { edit_type_form_configuration_path(type) }
    attribute :workflow, label: :"types.edit.workflow.tab", url: ->(type) { edit_type_workflow_path(type) }
    attribute :project_attributes,
              label: :"types.edit.project_attributes.tab",
              url: ->(type) { edit_type_project_attributes_path(type) }
    attribute :projects, label: :"types.edit.projects.tab", url: ->(type) { edit_type_projects_path(type) }
    attribute :export_configuration,
              label: :"types.edit.export_configuration.tab",
              url: ->(type) { edit_type_pdf_export_template_index_path(type) }
  end

  kind :statuses, menu_item: :statuses, scope: -> { Status.order(:position) }, url: ->(status) { edit_status_path(status) } do
    %i[name color_id default_done_ratio is_closed is_default is_readonly excluded_from_totals].each do |name|
      attribute name, label: -> { Status.human_attribute_name(name) }, field: "status[#{name}]"
    end
  end

  kind :priorities,
       menu_item: :priorities,
       scope: -> { IssuePriority.order(:position) },
       url: ->(priority) { edit_admin_settings_work_package_priority_path(priority) } do
    %i[name color_id active].each do |name|
      attribute name, label: -> { IssuePriority.human_attribute_name(name) }, field: "enumeration[#{name}]"
    end
    attribute :is_default, label: :label_default, field: "enumeration[is_default]"
  end

  kind :roles,
       menu_item: :roles,
       scope: -> { Role.where(type: %w[ProjectRole GlobalRole]).order(:builtin, :position) },
       url: ->(role) { edit_role_path(role) } do
    attribute :name, label: -> { Role.human_attribute_name(:name) }, field: "role[name]"

    attributes_from do
      enabled_modules = OpenProject::AccessControl.sorted_module_names(include_disabled: false)

      OpenProject::AccessControl.permissions.filter_map do |permission|
        next unless enabled_modules.include?(permission.project_module.to_s)

        Settings::EntityKinds::Attribute.new(
          :"permission_#{permission.name}",
          label: :"permission_#{permission.name}",
          group: :label_permissions,
          field: "role[permissions][]=#{permission.name}",
          if: ->(role) {
            RequestStore.fetch([:settings_search_assignable_permissions, role.id]) do
              Roles::BaseContract.new(role, User.current).assignable_permissions.map(&:name)
            end.include?(permission.name)
          }
        )
      end
    end
  end

  custom_field_attributes = lambda do
    visibility = ->(custom_field) { CustomFields::DetailsFieldVisibility.new(custom_field) }
    label = ->(name) { -> { I18n.t("activerecord.attributes.custom_field.#{name}") } }

    attribute :name, label: :label_name, field: "custom_field[name]"
    {
      default_value: ->(cf) {
        visibility.(cf).then { it.show_default_text_field? || it.show_default_bool_field? || it.show_default_rich_text_field? }
      },
      regexp: ->(cf) { visibility.(cf).show_regex_field? },
      min_length: ->(cf) { visibility.(cf).show_min_max_length_field? },
      max_length: ->(cf) { visibility.(cf).show_min_max_length_field? },
      min_value: ->(cf) { visibility.(cf).show_min_max_value_field? },
      max_value: ->(cf) { visibility.(cf).show_min_max_value_field? },
      multi_value: ->(cf) { visibility.(cf).show_multi_value_field? },
      has_comment: ->(cf) { visibility.(cf).show_has_comment_field? },
      is_required: ->(cf) { visibility.(cf).show_is_required_field? },
      is_for_all: ->(cf) { visibility.(cf).show_is_for_all_field? },
      is_filter: ->(cf) { visibility.(cf).show_is_filter_field? },
      searchable: ->(cf) { visibility.(cf).show_is_searchable_field? },
      admin_only: ->(cf) { visibility.(cf).show_admin_only_field? },
      editable: ->(cf) { visibility.(cf).show_editable_field? },
      visible_on_user_card: ->(cf) { visibility.(cf).show_on_user_card_field? }
    }.each do |name, condition|
      attribute name, label: label.(name), field: "custom_field[#{name}]", if: condition
    end
  end

  {
    work_package_custom_fields: ["WorkPackageCustomField", :work_package_custom_fields],
    version_custom_fields: ["VersionCustomField", :version_custom_fields],
    user_custom_fields: ["UserCustomField", :user_custom_fields_settings],
    group_custom_fields: ["GroupCustomField", :group_custom_fields],
    project_custom_fields: ["ProjectCustomField", :project_custom_fields_settings],
    time_entry_custom_fields: ["TimeEntryCustomField", :time_entry_custom_fields]
  }.each do |key, (custom_field_class, menu_item)|
    kind key,
         menu_item:,
         scope: -> { custom_field_class.constantize.order(:position) },
         url: ->(custom_field) { url_for([:edit, :admin, :settings, custom_field]) } do
      instance_exec(&custom_field_attributes)
    end
  end

  kind :oauth_applications,
       menu_item: :oauth_applications,
       scope: -> { Doorkeeper::Application.without_integration.where(builtin: false).order(:name) },
       url: ->(application) { edit_oauth_application_path(application) } do
    %i[name enabled redirect_uri confidential client_credentials_user_id].each do |name|
      attribute name, label: :"activerecord.attributes.doorkeeper/application.#{name}", field: "application[#{name}]"
    end
  end

  kind :ldap_connections,
       menu_item: :ldap_authentication,
       scope: -> { LdapAuthSource.order(:name) },
       url: ->(connection) { edit_ldap_auth_source_path(connection) } do
    %i[name host port account base_dn filter_string attr_login attr_mail].each do |name|
      attribute name, label: -> { LdapAuthSource.human_attribute_name(name) }, field: "ldap_auth_source[#{name}]"
    end
    attribute :tls_mode, label: :"ldap_auth_sources.connection_encryption", field: "ldap_auth_source[tls_mode]"
    attribute :verify_peer, label: :"ldap_auth_sources.tls_options.verify_peer", field: "ldap_auth_source[verify_peer]"
    attribute :attr_admin, label: -> { LdapAuthSource.human_attribute_name(:admin) }, field: "ldap_auth_source[attr_admin]"
    attribute :onthefly_register,
              label: -> { LdapAuthSource.human_attribute_name(:onthefly) },
              field: "ldap_auth_source[onthefly_register]"
  end

  kind :scim_clients,
       menu_item: :scim_clients,
       scope: -> { ScimClient.order(:name) },
       url: ->(client) { edit_admin_scim_client_path(client) },
       if: -> { EnterpriseToken.allows_to?(:scim_api) } do
    %i[name auth_provider_id authentication_method].each do |name|
      attribute name, label: -> { ScimClient.human_attribute_name(name) }, field: "scim_client[#{name}]"
    end
  end

  kind :groups, menu_item: :groups, scope: -> { Group.order(:lastname) }, name: :lastname,
                url: ->(group) { edit_group_path(group) } do
    attribute :name, label: -> { Group.human_attribute_name(:name) }, field: "group[lastname]"
    attribute :parent, label: -> { Group.human_attribute_name(:parent) }, field: "group[parent_id]"
  end

  kind :project_phase_definitions,
       menu_item: :project_phase_definitions_settings,
       scope: -> { Project::PhaseDefinition.order(:position) },
       url: ->(definition) { edit_admin_settings_project_phase_definition_path(definition) },
       if: -> { EnterpriseToken.allows_to?(:customize_life_cycle) } do
    %i[name color_id start_gate start_gate_name finish_gate finish_gate_name].each do |name|
      attribute name,
                label: -> { Project::PhaseDefinition.human_attribute_name(name) },
                field: "project_phase_definition[#{name}]"
    end
  end

  kind :jira_imports,
       menu_item: :jira_import,
       scope: -> { Import::Jira.order(created_at: :desc) },
       url: ->(import) { edit_admin_import_jira_path(import) } do
    %i[name url personal_access_token].each do |name|
      attribute name, label: :"admin.jira.form.fields.#{name}", field: "import_jira[#{name}]"
    end
  end

  kind :announcement,
       menu_item: :announcements,
       scope: -> { Announcement.order(:id) },
       name: :text,
       url: ->(_announcement) { edit_announcements_path } do
    attribute :text, label: :"announcements.content", field: "announcement[text]"
    attribute :show_until, label: :"announcements.show_until"
    attribute :active, label: :label_active, field: "announcement[active]"
  end

  kind :mcp_server,
       menu_item: :mcp_configurations,
       scope: -> { McpConfiguration.where(identifier: "mcp_server") },
       name: :title,
       url: ->(_configuration) { mcp_configurations_path },
       if: -> { EnterpriseToken.allows_to?(:mcp_server) } do
    attribute :enabled, label: -> { McpConfiguration.human_attribute_name(:enabled) }, field: "mcp_configuration[enabled]"
    attribute :title,
              label: -> { McpConfiguration.human_attribute_name(:title) },
              field: "mcp_configuration[title]",
              if: :enabled?.to_proc
    attribute :description,
              label: -> { McpConfiguration.human_attribute_name(:description) },
              field: "mcp_configuration[description]",
              if: :enabled?.to_proc
  end
end
