#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module ::TypesHelper
  def types_tabs
    [
      {
        name: 'settings',
        partial: 'types/form/settings',
        path: edit_type_tab_path(id: @type.id, tab: :settings),
        label: 'types.edit.settings'
      },
      {
        name: 'form_configuration',
        partial: 'types/form/form_configuration',
        path: edit_type_tab_path(id: @type.id, tab: :form_configuration),
        label: 'types.edit.form_configuration'
      },
      {
        name: 'projects',
        partial: 'types/form/projects',
        path: edit_type_tab_path(id: @type.id, tab: :projects),
        label: 'types.edit.projects'
      }
    ]
  end

  def icon_for_type(type)
    return unless type

    css_class = if type.is_milestone?
                  'color--milestone-icon'
                else
                  'color--phase-icon'
                end

    color = if type.color.present?
              type.color.hexcode
            else
              '#CCC'
            end

    content_tag(:span, ' ',
                class: css_class,
                style: "background-color: #{color}")
  end

  ##
  # Collect active and inactive form configuration groups for editing.
  def form_configuration_groups(type)
    available = type.work_package_attributes
    # First we create a complete list of all attributes.
    # Later we will remove those that are members of an attribute group.
    # This way attributes that were created after the las group definitions
    # will fall back into the inactives group.
    inactive = available.clone

    active_form = get_active_groups(type, available, inactive)
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

    # Modify the hash to match Rails array based +to_query+ transforms:
    # e.g., { columns: [1,2] }.to_query == "columns[]=1&columns[]=2" (unescaped)
    # The frontend will do that IFF the hash key is an array
    ::API::V3::Queries::QueryParamsRepresenter.new(group.attributes).to_json
  end

  private

  ##
  # Collect active attributes from the current form configuration.
  # Using the available attributes from +work_package_attributes+,
  # determines which attributes are not used
  def get_active_groups(type, available, inactive)
    type.attribute_groups.map do |group|
      {
        type: group.group_type,
        name: group.translated_key,
        attributes: active_group_attributes_map(group, available, inactive),
        query: query_to_query_props(group)
      }.tap do |group_obj|
        group_obj[:key] = group.key if group.internal_key?
      end
    end
  end

  def attr_form_map(key, represented)
    {
      key: key,
      is_cf: CustomField.custom_field_attribute?(key),
      is_required: represented[:required] && !represented[:has_default],
      translation: Type.translated_attribute_name(key, represented)
    }
  end
end
