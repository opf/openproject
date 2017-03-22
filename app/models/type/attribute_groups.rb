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

module Type::AttributeGroups
  extend ActiveSupport::Concern

  included do
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
        spent_time: :estimates_and_time
      }
    end

    # All known default
    mattr_accessor :default_groups do
      {
        people: :label_people,
        estimates_and_time: :label_estimates_and_time,
        details: :label_details,
        other: :label_other,
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
    groups = read_attribute :attribute_groups
    groups.presence || default_attribute_groups
  end

  ##
  # Returns the default +attribute_groups+ put together by
  # the default group map.
  def default_attribute_groups
    values =  work_package_attributes.keys.group_by { |key| map_attribute_to_group key }

    ordered = []
    default_groups.map do |groupkey, label_key|
      members = values[groupkey]
      ordered << [I18n.t(label_key), members.sort] if members.present?
    end

    ordered
  end

  ##
  # Map an AR attribute name to a group symbol,
  # using the +default_group_map+ as fallback.
  def map_attribute_to_group(name)
    if name =~ /custom/
      :other
    else
      default_group_map.fetch(name.to_sym, :details)
    end
  end

  def validate_attribute_group_names
    seen = Set.new
    attribute_groups.each do |group_key,_|
      errors.add(:attribute_groups, :group_without_name) unless group_key.present?
      errors.add(:attribute_groups, :duplicate_group, group: group_key) if seen.add?(group_key).nil?
    end
  end

  def validate_attribute_groups
    valid_attributes = work_package_attributes.keys
    attribute_groups.each do |_, attributes|
      attributes.each do |key|
        if valid_attributes.exclude? key
          errors.add(:attribute_groups, :attribute_unknown)
        end
      end
    end
  end
end
