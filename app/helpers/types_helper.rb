#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
  def icon_for_type(type)
    return unless type

    css_class = if type.is_milestone?
                  'timelines-milestone'
                else
                  'timelines-phase'
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

  private

  ##
  # Collect active attributes from the current form configuration.
  # Using the available attributes from +work_package_attributes+,
  # determines which attributes are not used
  def get_active_groups(type, available, inactive)
    type.non_query_attribute_groups.map do |group|
      extended_attributes =
        group.attributes
             .select { |key| inactive.delete(key) }
             .map! { |key| attr_form_map(key, available[key]) }

      [group, extended_attributes]
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
