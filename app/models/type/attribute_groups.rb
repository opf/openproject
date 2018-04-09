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
    before_save :write_attribute_groups_objects
    after_destroy :remove_attribute_groups_queries
    validate :validate_attribute_group_names
    validate :validate_attribute_groups
    serialize :attribute_groups, Array

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
    self.attribute_groups_objects ||= begin
      groups = custom_attribute_groups || default_attribute_groups

      to_attribute_group_class(groups)
    end

    # TODO: move appending of children default query to #default_attribute_groups
    # once query groups can be configured
    attribute_groups_objects + [::Type::QueryGroup.new(self, :children, default_children_query)]
  end

  def attribute_groups=(groups)
    self.attribute_groups_objects = groups.empty? ? nil : to_attribute_group_class(groups)
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

  def reload(*args)
    self.attribute_groups_objects = nil
    super
  end

  protected

  attr_accessor :attribute_groups_objects

  private

  def write_attribute_groups_objects
    return if attribute_groups_objects.nil?

    groups = attribute_groups_objects.map do |group|
      attributes = if group.is_a?(Type::QueryGroup)
                     query = group.query

                     query.save

                     [group.query_attribute_name]
                   else
                     group.attributes
                   end
      [group.key, attributes]
    end

    write_attribute(:attribute_groups, groups) if groups != default_attribute_groups

    cleanup_query_groups_queries
  end

  def custom_attribute_groups
    read_attribute(:attribute_groups).presence
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
    attribute_groups_objects.each do |group|
      if group.is_a?(Type::QueryGroup)
        validate_query_group(group)
      else
        validate_attribute_group(group)
      end
    end
  end

  def validate_query_group(group)
    query = group.query

    contract_class = query.persisted? ? Queries::UpdateContract : Queries::CreateContract
    contract = contract_class.new(query, User.current)

    unless contract.validate
      errors.add(:attribute_groups, :query_invalid)
    end
  end

  def validate_attribute_group(group)
    valid_attributes = work_package_attributes.keys

    group.attributes.each do |key|
      if key.is_a?(String) && valid_attributes.exclude?(key)
        errors.add(:attribute_groups, :attribute_unknown)
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
      attributes = group[1]
      first_attribute = attributes[0]
      key = group[0]

      if first_attribute.is_a?(Query)
        new_query_group(key, first_attribute)
      elsif first_attribute.is_a?(Symbol) && Type::QueryGroup.query_attribute?(first_attribute)
        query = Query.find_by(id: Type::QueryGroup.query_attribute_id(first_attribute))
        new_query_group(key, query)
      else
        new_attribute_group(key, attributes)
      end
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

  def new_attribute_group(key, attributes)
    Type::AttributeGroup.new(self, key, attributes)
  end

  def new_query_group(key, query)
    Type::QueryGroup.new(self, key, query)
  end

  def cleanup_query_groups_queries
    return unless attribute_groups_changed?

    new_groups = read_attribute(:attribute_groups)
    old_groups = attribute_groups_was

    ids = (old_groups.map(&:last).flatten - new_groups.map(&:last).flatten)
          .map { |k| ::Type::QueryGroup.query_attribute_id(k) }
          .compact

    Query.destroy(ids)
  end

  def remove_attribute_groups_queries
    attribute_groups
      .select { |g| g.is_a?(Type::QueryGroup) }
      .map(&:query)
      .each(&:destroy)
  end
end
