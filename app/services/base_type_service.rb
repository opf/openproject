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

class BaseTypeService
  attr_accessor :type

  def call(permitted_params: {}, unsafe_params: {})
    update(permitted_params, unsafe_params)
  end

  private

  def update(permitted_params = {}, unsafe_params = {})
    success = Type.transaction do
      permitted = permitted_params
      permitted.delete(:attribute_groups)
      permitted.delete(:attribute_visibility)

      type.attributes = permitted

      if unsafe_params[:attribute_groups].present?
        type.attribute_groups =
          JSON.parse(unsafe_params[:attribute_groups])
              .map do |group|
                [(group[2] ? group[0].to_sym : group[0]), group[1]]
              end
      end
      if unsafe_params[:attribute_visibility].present?
        type.attribute_visibility = JSON.parse(unsafe_params[:attribute_visibility])
      end

      set_date_attribute_visibility
      set_active_custom_fields

      if type.save
        true
      else
        raise ActiveRecord::Rollback
      end
    end

    ServiceResult.new(success: success,
                      errors: type.errors)
  end

  def set_date_attribute_visibility
    if type.is_milestone? && !type.attribute_visibility['date']
      set_date_milestone_attribute_visibility
    elsif !type.is_milestone? && type.attribute_visibility['date']
      set_date_non_milestone_attribute_visibility
    end
  end

  def set_date_milestone_attribute_visibility
    values = [type.attribute_visibility.delete('start_date'),
              type.attribute_visibility.delete('due_date')]

    type.attribute_visibility['date'] = max_visibility values
  end

  def set_date_non_milestone_attribute_visibility
    visibility = type.attribute_visibility.delete('date')

    type.attribute_visibility['start_date'] = visibility
    type.attribute_visibility['due_date'] = visibility
  end

  ##
  # Syncs visibility settings for custom fields with enabled custom fields
  # for this type. If a custom field is hidden it is removed from the
  # custom_field_ids list.
  def set_active_custom_fields
    enabled = ['default', 'visible']

    active_cf_ids = type
                    .attribute_visibility
                    .select { |key, value| key =~ /custom_field_/ && enabled.include?(value) }
                    .map { |key, _| key.gsub(/^custom_field_/, '').to_i }

    type.custom_field_ids = active_cf_ids
  end

  module Functions
    module_function

    def max_visibility(values)
      ['visible', 'default', 'hidden'].detect { |v| values.include?(v) } || 'default'
    end
  end

  include Functions
end
