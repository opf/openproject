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

module Type::AttributeVisibility
  extend ActiveSupport::Concern

  included do
    serialize :attribute_visibility, Hash
    validates_each :attribute_visibility do |record, _attr, visibility|
      visibility.each do |attr_name, value|
        unless attribute_visibilities.include? value.to_s
          record.errors.add(:attribute_visibility, "for '#{attr_name}' cannot be '#{value}'")
        end
      end
    end
  end

  class_methods do
    ##
    # The possible visibility values for a work package attribute
    # as defined by a type are:
    #
    #   - default The attribute is displayed in forms if it has a value.
    #   - visible The attribute is displayed in forms even if empty.
    #   - hidden  The attribute is hidden in forms even if it has a value.
    def attribute_visibilities
      ['visible', 'hidden', 'default']
    end

    def default_attribute_visibility
      'visible'
    end
  end

  ##
  # Calculates the visibility for all attributes of the given type.
  #
  # @param type [Type] Type for which to get the attribute visibilities.
  # @return [Hash{String => String}] A map from each attribute name to the attribute's visibility.
  def type_attribute_visibility
    enabled_cfs = custom_field_ids.join("|")
    visibility = ::Type.all_work_package_form_attributes
      .keys
      .select { |name| name !~ /^custom_field/ || name =~ /^custom_field_(#{enabled_cfs})$/ }
      .map { |name| [name, attr_visibility(name) || "default"] }
      .to_h
  end

  ##
  # Checks visibility of a work package type's attribute.
  #
  # @param name [String] Name of the field of which to check the visibility.
  # @param type [Type] Work package type whose field visibility is checked.
  # @return [String] Either 'hidden', 'default' or 'visible'.
  def attr_visibility(name)
    if name =~ /^custom_field_/
      custom_field_visibility name
    elsif name == 'date' && !is_milestone
      non_milestone_date_field_visibility
    else
      attribute_visibility[name]
    end
  end

  #
  # Bases visibility of custom fields on `type.custom_field_ids`
  # if no visibility is defined yet. After the first update
  # attribute_visibility and custom_field_ids will be kept in sync
  # by the type service.
  def custom_field_visibility(name)
    id = name.split('_').last.to_i
    value = attribute_visibility[name]

    if value.nil? || value == 'hidden'
      if custom_field_ids.include?(id)
        'default'
      else
        'hidden'
      end
    else
      value
    end
  end

  def non_milestone_date_field_visibility
    values = [
      attribute_visibility['start_date'],
      attribute_visibility['due_date']
    ]

    BaseTypeService::Functions.max_visibility values
  end

end
