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

module ::TypesHelper
  include CustomFieldsHelper

  SETTINGS_TAB = "settings"

  # rubocop:disable Rails/HelperInstanceVariable
  def types_tabs # rubocop:disable Metrics/AbcSize
    project = variant_scope_project
    variant = tab_variant

    [
      settings_tab,
      type_tab("details", edit_variant_details_path(project, variant), aspect: nil),
      type_tab("defaults", edit_variant_defaults_path(project, variant), aspect: TypeVariant::DEFAULTS),
      variants_tab,
      type_tab("form_configuration", edit_variant_form_configuration_path(project, variant), aspect: nil),
      type_tab("workflow", edit_variant_workflow_path(project, variant), aspect: nil),
      type_tab("project_attributes", edit_variant_project_attributes_path(project, variant),
               aspect: TypeVariant::PROJECT_ATTRIBUTES),
      projects_tab,
      type_tab("export_configuration", edit_variant_pdf_export_template_index_path(project, variant),
               aspect: TypeVariant::PDF_EXPORT,
               view_component: WorkPackageTypes::ExportConfigurationComponent)
    ].compact
  end

  def type_tab(name, path, aspect:, label: I18n.t("types.edit.#{name}.tab"), **extra)
    { name:, path:, label:, aspect:, **extra }
  end

  def tab_variant
    @variant || @type.default_variant
  end

  def settings_tab
    return if @variant.nil? || @variant.is_default_variant?

    type_tab(SETTINGS_TAB, variant_settings_path(variant_scope_project, @variant),
             aspect: nil, label: I18n.t("types.edit.overview.tab"))
  end

  # A variant a project owns may only ever be used there, an administrator included, so which
  # projects use it is not a question. Mirrors Wizard::Steps.available_for.
  def projects_tab
    return if variant_scope_project || @variant&.project_owned?

    type_tab("projects", edit_variant_projects_path(tab_variant), aspect: nil)
  end

  def variants_tab
    return if @variant.present? && !@variant.is_default_variant?
    # This lists every project's variants of the type, so it is administration's view of them.
    return if variant_scope_project

    type_tab("variants", type_variants_path(type_id: @type.id),
             aspect: nil, label: TypeVariant.model_name.human(count: 2))
  end
  # rubocop:enable Rails/HelperInstanceVariable

  # The variant may be another one than the page's, which the project routes only offer when the
  # project owns it.
  def aspect_edit_path(variant, aspect)
    project = variant_scope_project if variant_scope_project && variant.project_id == variant_scope_project.id

    case aspect
    when TypeVariant::DEFAULTS
      edit_variant_defaults_path(project, variant)
    when TypeVariant::PDF_EXPORT
      edit_variant_pdf_export_template_index_path(project, variant)
    when TypeVariant::PROJECT_ATTRIBUTES
      edit_variant_project_attributes_path(project, variant)
    else
      edit_variant_form_configuration_path(project, variant)
    end
  end

  def icon_for_type(type)
    return unless type

    css_class = if type.is_milestone?
                  "color--milestone-icon"
                else
                  "color--phase-icon"
                end

    color = if type.color.present?
              type.color.hexcode
            else
              "#CCC"
            end

    content_tag(:span, " ",
                class: css_class,
                style: "background-color: #{color}",
                **accessible_type_icon_attributes(type))
  end

  # The diamond shape is the only thing distinguishing a milestone from an
  # ordinary type, so it needs a text equivalent. role="img" is what lets the
  # title count as the accessible name on an otherwise roleless span. Ordinary
  # types say nothing: the type name follows in the adjacent text.
  def accessible_type_icon_attributes(type)
    return { aria: { hidden: true } } unless type.is_milestone?

    { role: "img", title: I18n.t("types.milestone_indicator") }
  end

  ##
  # Collect active and inactive form configuration groups for editing.
  def form_configuration_groups(variant)
    available = variant.work_package_attributes
    # First we create a complete list of all attributes.
    # Later we will remove those that are members of an attribute group.
    # This way attributes that were created after the las group definitions
    # will fall back into the inactives group.
    inactive = available.clone
    membership_ids = variant.try(:membership_ids) || {}

    active_form = get_active_groups(variant, available, inactive, membership_ids)
    inactive_form = inactive
                      .map { |key, attribute| attr_form_map(key, attribute, id: membership_ids[key.to_s]) }
                      .sort_by { |attr| attr[:translation] }

    {
      actives: active_form,
      inactives: inactive_form
    }
  end

  def active_group_attributes_map(group, available, inactive, required_keys: [], membership_ids: {})
    return nil unless group.group_type == :attribute

    group.attributes
         .select { |key| inactive.delete(key) }
         .map! { |key| attr_form_map(key, available[key], id: membership_ids[key.to_s], required_keys:) }
  end

  def query_to_query_props(group)
    return nil unless group.group_type == :query

    query = group.attributes
    return nil if query.blank?

    # Reduce the query to its valid subset to avoid errors loading the form
    query.valid_subset!

    # Modify the hash to match Rails array based +to_query+ transforms:
    # e.g., { columns: [1,2] }.to_query == "columns[]=1&columns[]=2" (unescaped)
    # The frontend will do that IFF the hash key is an array
    ::API::V3::Queries::QueryParamsRepresenter.new(query).to_json
  end

  private

  ##
  # Collect active attributes from the current form configuration.
  # Using the available attributes from +work_package_attributes+,
  # determines which attributes are not used
  def get_active_groups(variant, available, inactive, membership_ids = {})
    required_keys = variant.required_attributes.map(&:to_s)

    variant.attribute_groups.map do |group|
      {
        id: group.record_id,
        key: group.key,
        type: group.group_type,
        name: group.translated_key,
        element_key: exclusion_element_key(group),
        attributes: active_group_attributes_map(group, available, inactive, required_keys:, membership_ids:),
        query: query_to_query_props(group)
      }
    end
  end

  # The key a query group is excluded by. Attribute groups have none, their rows carry their own,
  # and neither does a group whose query was deleted: the key is derived from the query id.
  def exclusion_element_key(group)
    return nil unless group.group_type == :query && group.query.present?

    group.query_attribute_name.to_s
  end

  def attr_form_map(key, represented, id: nil, required_keys: [])
    {
      id:,
      key:,
      is_cf: CustomField.custom_field_attribute?(key),
      required_globally: represented[:required].present?,
      required_for_variant: required_keys.include?(key.to_s),
      translation: TypeVariant.translated_attribute_name(key, represented),
      field_format_label: field_format_label(represented)
    }
  end

  def field_format_label(represented)
    if represented[:is_cf]
      label_for_custom_field_format(represented[:field_format])
    else
      I18n.t("label_builtin")
    end
  end
end
