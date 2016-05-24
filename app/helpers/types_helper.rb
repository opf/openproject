#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

  ##
  # Provides a map of all work package form attributes as seen when creating
  # or updating a work package. Through this map it can be checked whether or
  # not an attribute is required.
  #
  # E.g.
  #
  #   ::TypesHelper.work_package_form_attributes['author'][:required] # => true
  #
  # @return [Hash{String => Hash}] Map from attribute names to options.
  def work_package_form_attributes(merge_date: false)
    rattrs = API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter.representable_attrs
    definitions = rattrs[:definitions]
    skip = ['_type', 'links', 'parent_id', 'parent', 'description']
    attributes = definitions.keys
      .reject { |key| skip.include? key }
      .map { |key| [key, definitions[key]] }.to_h

    # within the form date is shown as a single entry including start and due
    if merge_date
      attributes['date'] = { required: false, has_default: false }
      attributes.delete 'due_date'
      attributes.delete 'start_date'
    end

    WorkPackageCustomField.all.each do |field|
      attributes["custom_field_#{field.id}"] = {
        required: field.is_required,
        has_default: field.default_value,
        display_name: field.name
      }
    end

    attributes
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

  def translated_attribute_name(name, attr)
    if attr[:name_source]
      attr[:name_source].call
    else
      attr[:display_name] || attr_translate(name)
    end
  end

  ##
  # There isn't actually a 'date' field for work packages.
  # There are two fields: 'start_date' and 'due_date'
  # Though they are displayed together in one row, as one 'field'.
  # Since the schema doesn't know any field named 'date' we
  # derive the visibility for the imaginary 'date' field from
  # the actual schema values of 'due_date' and 'start_date'.
  #
  # 'visible' > 'default' > 'hidden'
  # Meaning, for instance, that if at least one field is 'visible'
  # both will be shown. Even if the other is 'hidden'.
  #
  # Note: this is duplicated in wp-field.service.js
  #
  # Also bases visibility of custom fields on `type.custom_field_ids`
  # if no visibility is defined yet. After the first update
  # attribute_visibility and custom_field_ids will be kept in sync
  # by the types controller (see #extract_custom_field_ids).
  def attr_visibility(name)
    if name == 'date'
      values = ['start_date', 'due_date'].map do |n|
        @type.attribute_visibility[n]
      end

      if values.include? 'visible'
        'visible'
      elsif values.include? 'default'
        'default'
      elsif values.include? 'hidden'
        'hidden'
      else
        nil
      end
    elsif name =~ /^custom_field_/
      id = name.split('_').last.to_i
      value = @type.attribute_visibility[name]

      if value.nil? || value == 'hidden'
        if @type.custom_field_ids.include?(id)
          'default'
        else
          'hidden'
        end
      else
        value
      end
    else
      @type.attribute_visibility[name]
    end
  end
end
