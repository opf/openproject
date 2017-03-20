#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module ::TypesHelper
  def icon_for_type(type)
    return unless type

    if type.is_milestone?
      css_class = 'timelines-milestone'
    else
      css_class = 'timelines-phase'
    end
    if type.color.present?
      color = type.color.hexcode
    else
      color = '#CCC'
    end

    content_tag(:span, ' ',
                class: css_class,
                style: "background-color: #{color}")
  end

  module_function

  def form_configuration_groups(type)
    attributes = type.work_package_attributes
    # First we create a complete list of all attributes.
    # Later we will remove those that are members of an attribute group.
    # This way attributes that were created after the las group definitions
    # will fall back into the inactives group.
    inactive_attributes = attributes.clone

    actives = type.attribute_groups.map do |group|
      extended_attributes = group.second.select do |key|
        # The group's attribute keys could be out of date. Check presence.
        if inactive_attributes.key?(key)
          inactive_attributes.delete(key)
          true
        else
          false
        end
      end
      extended_attributes.map! do |key|
        {
          key: key,
          always_visible: attr_visibility(key, type) == 'visible',
          translation: translated_attribute_name(key, attributes[key])
        }
      end

      extended_group = { key: group[0], translation: group_translate(group[0]) }

      [extended_group, extended_attributes]
    end

    inactives = inactive_attributes.map do |key, attribute|
      {
        key: key,
        attribute: attribute,
        translation: translated_attribute_name(key, attribute)
      }
    end.sort_by { |_key, _attribute, translation| translation }

    { actives: actives, inactives: inactives }
  end

  def attr_i18n_key(name)
    if name == 'percentage_done'
      'done_ratio'
    else
      name
    end
  end

  def attr_translate(name)
    if name == 'date'
      I18n.t('label_date')
    else
      key = attr_i18n_key(name)
      I18n.t("activerecord.attributes.work_package.#{key}", default: '')
        .presence || I18n.t("attributes.#{key}")
    end
  end

  def group_translate(name)
    if ['details', 'estimates_and_time', 'other', 'people'].include? name
      I18n.t("label_#{name}")
    else
      name
    end
  end

  def translated_attribute_name(name, attr)
    if attr[:name_source]
      attr[:name_source].call
    else
      attr[:display_name] || attr_translate(name)
    end
  end

  ##
  # Calculates the visibility for all attributes of the given type.
  #
  # @param type [Type] Type for which to get the attribute visibilities.
  # @return [Hash{String => String}] A map from each attribute name to the attribute's visibility.
  def type_attribute_visibility(type)
    enabled_cfs = type.custom_field_ids.join("|")
    visibility = ::Type.all_work_package_form_attributes
      .keys
      .select { |name| name !~ /^custom_field/ || name =~ /^custom_field_(#{enabled_cfs})$/ }
      .map { |name| [name, attr_visibility(name, type) || "default"] }
      .to_h
  end

  ##
  # Updates the given type's attribute visibility map.
  #
  # @param type [Type] The type to be updated
  # @return [Type] The updated type
  def update_type_attribute_visibility!(type)
    type.update! attribute_visibility: type_attribute_visibility(type)
  end

  ##
  # Checks visibility of a work package type's attribute.
  #
  # @param name [String] Name of the field of which to check the visibility.
  # @param type [Type] Work package type whose field visibility is checked.
  # @return [String] Either 'hidden', 'default' or 'visible'.
  def attr_visibility(name, type)
    if name =~ /^custom_field_/
      custom_field_visibility name, type
    elsif name == 'date' && !type.is_milestone
      non_milestone_date_field_visibility type
    else
      type.attribute_visibility[name]
    end
  end

  #
  # Bases visibility of custom fields on `type.custom_field_ids`
  # if no visibility is defined yet. After the first update
  # attribute_visibility and custom_field_ids will be kept in sync
  # by the type service.
  def custom_field_visibility(name, type)
    id = name.split('_').last.to_i
    value = type.attribute_visibility[name]

    if value.nil? || value == 'hidden'
      if type.custom_field_ids.include?(id)
        'default'
      else
        'hidden'
      end
    else
      value
    end
  end

  def non_milestone_date_field_visibility(type)
    values = [type.attribute_visibility['start_date'],
              type.attribute_visibility['due_date']]

    BaseTypeService::Functions.max_visibility values
  end
end
