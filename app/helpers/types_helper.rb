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

  # rubocop:disable Rails/HelperInstanceVariable
  # The projects tab is dropped from a project: a variant it owns is only ever used there.
  def types_tabs # rubocop:disable Metrics/AbcSize
    variant_args = type_variant_tab_args

    tabs = [
      {
        name: "details",
        path: edit_type_details_path(**variant_args),
        label: I18n.t("types.edit.details.tab")
      },
      {
        name: "defaults",
        path: edit_type_defaults_path(**variant_args),
        label: I18n.t("types.edit.defaults.tab")
      },
      variants_tab,
      {
        name: "form_configuration",
        path: edit_type_form_configuration_path(**variant_args),
        label: I18n.t("types.edit.form_configuration.tab")
      },
      {
        name: "workflow",
        path: edit_type_workflow_path(**variant_args),
        label: I18n.t("types.edit.workflow.tab")
      },
      {
        name: "project_attributes",
        path: edit_type_project_attributes_path(**variant_args),
        label: I18n.t("types.edit.project_attributes.tab")
      },
      {
        name: "projects",
        path: (edit_type_projects_path(**variant_args) if projects_tab?),
        label: I18n.t("types.edit.projects.tab")
      },
      {
        name: "export_configuration",
        path: edit_type_pdf_export_template_index_path(**variant_args),
        label: I18n.t("types.edit.export_configuration.tab"),
        view_component: WorkPackageTypes::ExportConfigurationComponent
      }
    ].compact

    tabs.select { |tab| tab[:path] }
  end

  def type_variant_tab_args
    @variant&.path_args || { type_id: @type.id }
  end

  # A variant a project owns may only ever be used there, an administrator included, so which
  # projects use it is not a question. Mirrors Wizard::Steps.available_for.
  def projects_tab? = variant_scope_project.nil? && !@variant&.project_owned?

  def variants_tab
    return unless OpenProject::FeatureDecisions.type_variants_active?
    return if @variant.present? && !@variant.is_default_variant?
    # This lists every project's variants of the type, so it is administration's view of them.
    return if variant_scope_project

    {
      name: "variants",
      path: type_variants_path(type_id: @type.id),
      label: TypeVariant.model_name.human(count: 2)
    }
  end
  # rubocop:enable Rails/HelperInstanceVariable

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

    active_form = get_active_groups(variant, available, inactive)
    inactive_form = inactive
                      .map { |key, attribute| attr_form_map(key, attribute) }
                      .sort_by { |attr| attr[:translation] }

    {
      actives: active_form,
      inactives: inactive_form
    }
  end

  def active_group_attributes_map(group, available, inactive)
    return nil unless group.group_type == :attribute

    group.attributes
         .select { |key| inactive.delete(key) }
         .map! { |key| attr_form_map(key, available[key]) }
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
  def get_active_groups(variant, available, inactive)
    variant.attribute_groups.map do |group|
      {
        key: group.key,
        type: group.group_type,
        name: group.translated_key,
        element_key: exclusion_element_key(group),
        attributes: active_group_attributes_map(group, available, inactive),
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

  def attr_form_map(key, represented)
    {
      key:,
      is_cf: CustomField.custom_field_attribute?(key),
      is_required: represented[:required] && !represented[:has_default],
      translation: TypeVariant.translated_attribute_name(key, represented),
      field_format_label: field_format_label(represented)
    }
  end

  def field_format_label(represented)
    if represented[:is_cf]
      label_for_custom_field_format(represented[:field_format])
    else
      I18n.t("types.edit.form_configuration.builtin_field")
    end
  end
end
