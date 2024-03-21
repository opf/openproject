#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class BaseTypeService
  include Shared::BlockService
  include Contracted

  attr_accessor :contract_class, :type, :user

  def initialize(type, user)
    self.type = type
    self.user = user
    self.contract_class = ::Types::BaseContract
  end

  def call(params, options, &)
    result = update(params, options)

    block_with_result(result, &)
  end

  private

  def update(params, options)
    success = false
    errors = type.errors

    Type.transaction do
      success, errors = set_params_and_validate(params)
      if success
        after_type_save(params, options)
      else
        raise(ActiveRecord::Rollback)
      end
    end

    ServiceResult.new(success:,
                      errors:,
                      result: type)
  rescue StandardError => e
    ServiceResult.failure.tap do |result|
      result.errors.add(:base, e.message)
    end
  end

  def set_params_and_validate(params)
    # Only set attribute groups when it exists
    # (Regression #28400)
    unless params[:attribute_groups].nil?
      set_attribute_groups(params)
    end

    # This should go before `set_scalar_params` call to get the
    # project_ids, custom_field_ids diffs from the type and the params
    set_active_custom_fields

    if params[:project_ids].present?
      set_active_custom_fields_for_project_ids(params[:project_ids])
    end

    set_scalar_params(params)

    validate_and_save(type, user)
  end

  def set_scalar_params(params)
    type.attributes = params.except(:attribute_groups)
  end

  def set_attribute_groups(params)
    if params[:attribute_groups].empty?
      type.reset_attribute_groups
    else
      type.attribute_groups = parse_attribute_groups_params(params)
    end
  end

  def parse_attribute_groups_params(params)
    return if params[:attribute_groups].nil?

    transform_attribute_groups(params[:attribute_groups])
  end

  def after_type_save(_params, _options)
    # noop to be overwritten by subclasses
  end

  def transform_attribute_groups(groups)
    groups.map do |group|
      if group['type'] == 'query'
        transform_query_group(group)
      else
        transform_attribute_group(group)
      end
    end
  end

  def transform_attribute_group(group)
    name =
      if group['key']
        group['key'].to_sym
      else
        group['name']
      end

    [
      name,
      group['attributes'].pluck('key')
    ]
  end

  def transform_query_group(group)
    name = group['name']
    props = JSON.parse group['query']

    query = Query.new_default(name: "Embedded table: #{name}")

    query.extend(OpenProject::ChangedBySystem)
    query.change_by_system do
      query.user = User.system
    end

    ::API::V3::UpdateQueryFromV3ParamsService
      .new(query, user)
      .call(props.with_indifferent_access)

    query.show_hierarchies = false

    [
      name,
      [query]
    ]
  end

  ##
  # Syncs attribute group settings for custom fields with enabled custom fields
  # for this type. If a custom field is not in a group, it is removed from the
  # custom_field_ids list.
  def set_active_custom_fields
    new_cf_ids_to_add = active_custom_field_ids - type.custom_field_ids
    type.custom_field_ids = active_custom_field_ids
    set_active_custom_fields_for_projects(type.projects,
                                          new_cf_ids_to_add)
  end

  def active_custom_field_ids
    @active_custom_field_ids ||= begin
      active_cf_ids = []

      type.attribute_groups.each do |group|
        group.members.each do |attribute|
          if CustomField.custom_field_attribute? attribute
            active_cf_ids << attribute.gsub(/^custom_field_/, '').to_i
          end
        end
      end
      active_cf_ids.uniq
    end
  end

  def set_active_custom_fields_for_projects(projects, custom_field_ids)
    values = projects
               .to_a
               .product(custom_field_ids)
               .map { |p, cf_ids| { project_id: p.id, custom_field_id: cf_ids } }

    return if values.empty?

    CustomFieldsProject.insert_all(values)
  end

  def set_active_custom_fields_for_project_ids(project_ids)
    new_project_ids_to_activate_cfs = project_ids.reject(&:empty?).map(&:to_i) - type.project_ids
    set_active_custom_fields_for_projects(
      Project.where(id: new_project_ids_to_activate_cfs),
      type.custom_field_ids
    )
  end
end
