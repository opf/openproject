#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChilittProject, which is a fork of Redmine. The copyright follows:
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

class BaseTypeService
  include Shared::BlockService

  attr_accessor :type, :user

  def initialize(user)
    self.user = user
  end

  def call(params, options, &block)
    result = update(params, options)

    block_with_result(result, &block)
  end

  private

  def update(params, options)
    success = Type.transaction do
      set_scalar_params(params)
      set_attribute_groups(params)
      set_active_custom_fields

      if type.save
        after_type_save(params, options)
        true
      else
        raise(ActiveRecord::Rollback)
      end
    end

    ServiceResult.new(success: success,
                      errors: type.errors,
                      result: type)
  end

  def set_scalar_params(params)
    type.attributes = params.except(:attribute_groups)
  end

  def set_attribute_groups(params)
    if params[:attribute_groups].present?
      type.attribute_groups = parse_attribute_groups_params(params)
    else
      type.reset_attribute_groups
    end
  end

  def parse_attribute_groups_params(params)
    return if params[:attribute_groups].nil?

    transform_params_to_query(params[:attribute_groups])
  end

  def after_type_save(_params, _options)
    # noop to be overwritten by subclasses
  end

  def transform_params_to_query(groups)
    groups.each_with_index do |(name, attributes), index|
      next unless attributes.is_a? Hash

      query = Query.new_default(name: "Embedded subelements: #{name}")

      ::API::V3::UpdateQueryFromV3ParamsService
        .new(query, user)
        .call(attributes.with_indifferent_access)

      query.show_hierarchies = false
      query.add_filter('parent', '=', ::Queries::Filters::TemplatedValue::KEY)

      groups[index][1] = [query]
    end
  end

  ##
  # Syncs attribute group settings for custom fields with enabled custom fields
  # for this type. If a custom field is not in a group, it is removed from the
  # custom_field_ids list.
  def set_active_custom_fields
    active_cf_ids = []

    type.attribute_groups.each do |group|
      group.members.each do |attribute|
        if CustomField.custom_field_attribute? attribute
          active_cf_ids << attribute.gsub(/^custom_field_/, '').to_i
        end
      end
    end

    type.custom_field_ids = active_cf_ids.uniq
  end
end
