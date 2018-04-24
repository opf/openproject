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

class BaseTypeService
  attr_accessor :type

  def call(permitted_params: {}, unsafe_params: {})
    update(permitted_params, unsafe_params)
  end

  private

  def update(permitted_params = {}, unsafe_params = {})
    success = Type.transaction do
      set_permitted_params(permitted_params)
      set_attribute_groups(unsafe_params)
      set_active_custom_fields

      type.save or raise(ActiveRecord::Rollback)
    end

    ServiceResult.new(success: success,
                      errors: type.errors)
  end

  def set_permitted_params(params)
    permitted = params
    permitted.delete(:attribute_groups)

    type.attributes = permitted
  end

  def set_attribute_groups(params)
    groups = parse_attribute_groups_params(params)
    type.attribute_groups = groups if groups
  end

  def parse_attribute_groups_params(params)
    return unless params[:attribute_groups].present?

    groups = JSON
             .parse(params[:attribute_groups])
             .map { |group| [(group[2] ? group[0].to_sym : group[0]), group[1]] }

    transform_query_params_to_query(groups)

    groups
  end

  def transform_query_params_to_query(groups)
    groups.each_with_index do |(_name, attributes), index|
      next unless attributes.is_a? Hash
      next if attributes.values.compact.empty?

      # HACK: provide user via parameters
      # have sensible name (although it should never be visible)
      call = ::API::V3::UpdateQueryFromV3ParamsService
             .new(Query.new_default(name: 'some_name'), User.current)
             .call(attributes.with_indifferent_access)

      query = call.result

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
