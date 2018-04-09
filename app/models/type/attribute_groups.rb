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

module Type::AttributeGroups
  extend ActiveSupport::Concern

  included do
    validate :validate_attribute_group_names
    validate :validate_attribute_groups
    serialize :attribute_groups, ::Type::AttributeGroupsSerializer

    # Mapping from AR attribute name to a default group
    # May be extended by plugins
    mattr_accessor :default_group_map do
      {
        author: :people,
        assignee: :people,
        responsible: :people,
        estimated_time: :estimates_and_time,
        spent_time: :estimates_and_time,
        priority: :details
      }
    end

    # All known default
    mattr_accessor :default_groups do
      {
        people: :label_people,
        estimates_and_time: :label_estimates_and_time,
        details: :label_details,
        other: :label_other,
        children: :'activerecord.attributes.work_package.children'
      }
    end
  end

  class_methods do
    ##
    # Add a new default group name
    def add_default_group(name, label_key)
      default_groups[name.to_sym] = label_key
    end

    ##
    # Add a mapping from attribute key to an existing default group
    def add_default_mapping(group, *keys)
      unless default_groups.include? group
        raise ArgumentError, "Can't add mapping for '#{keys.inspect}'. Unknown default group '#{group}'."
      end

      keys.each do |key|
        default_group_map[key.to_sym] = group
      end
    end
  end

  ##
  # Read the serialized attribute groups, if customized.
  # Otherwise, return +default_attribute_groups+
  def attribute_groups
    groups = custom_attribute_groups || default_attribute_groups

    groups = to_attribute_group_class(groups)

    groups + [::Type::QueryGroup.new(self, :children, default_children_query)]
  end

  ##
  # Returns the default +attribute_groups+ put together by
  # the default group map.
  def default_attribute_groups
    values = work_package_attributes_by_default_group_key

    default_groups.keys.each_with_object([]) do |groupkey, array|
      members = values[groupkey]
      array << [groupkey, members] if members.present?
    end
  end

  # TODO: remove once queries can be configured as well
  def non_query_attribute_groups
    attribute_groups.select { |g| g.is_a?(Type::AttributeGroup) }
  end

  private

  def custom_attribute_groups
    groups = read_attribute :attribute_groups
    # The attributes might not be present anymore, for instance when you remove
    # a plugin leaving an empty group behind. If we did not delete such a
    # group, the admin saving such a form configuration would encounter an
    # unexpected/unexplicable validation error.
    valid_keys = work_package_attributes.keys
    groups.each do |_, attributes|
      attributes.select! { |attribute| valid_keys.include? attribute }
    end

    groups.presence
  end

  def default_group_key(key)
    if CustomField.custom_field_attribute?(key)
      :other
    else
      default_group_map.fetch(key.to_sym, :details)
    end
  end

  def validate_attribute_group_names
    seen = Set.new
    attribute_groups.each do |group|
      errors.add(:attribute_groups, :group_without_name) unless group.key.present?
      errors.add(:attribute_groups, :duplicate_group, group: group.key) if seen.add?(group.key).nil?
    end
  end

  def validate_attribute_groups
    valid_attributes = work_package_attributes.keys
    non_query_attribute_groups.each do |group|
      group.attributes.each do |key|
        if key.is_a?(String) && valid_attributes.exclude?(key)
          errors.add(:attribute_groups, :attribute_unknown)
        end
      end
    end
  end

  def work_package_attributes_by_default_group_key
    work_package_attributes
      .keys
      .reject { |key| CustomField.custom_field_attribute?(key) && !has_custom_field?(key) }
      .group_by { |key| default_group_key(key.to_sym) }
  end

  def to_attribute_group_class(groups)
    groups.map do |group|
      Type::AttributeGroup.new(self, group[0], group[1])
    end
  end

  def default_children_query
    query = Query.new_default
    query.column_names = %w(id type subject)
    query.show_hierarchies = false
    query.filters = []
    query.add_filter('parent', '=', ::Queries::Filters::TemplatedValue::KEY)
    query
  end
end
