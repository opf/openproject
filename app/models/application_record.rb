# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class ApplicationRecord < ActiveRecord::Base
  include ::OpenProject::Acts::Watchable
  include ::OpenProject::Acts::Favoritable

  self.abstract_class = true

  ##
  # Determine whether this resource was just created ?
  def just_created?
    saved_change_to_attribute?(:id)
  end

  ##
  # Returns whether the given attribute is free of errors
  def valid_attribute?(attribute)
    errors.clear

    # run validations for specified attribute only.
    self.class.validators_on(attribute).each do |validator|
      validator.validate_each(self, attribute, public_send(attribute))
    end

    errors[attribute].empty?
  end

  # We want to add a validation error whenever someone sets a property that we don't know.
  # However AR will cleverly try to resolve the value for erroneous properties. Thus we need
  # to hook into this method and return nil for unknown properties to avoid NoMethod errors...
  def read_attribute_for_validation(attribute)
    super if respond_to?(attribute)
  end

  ##
  # Get the newest recently changed resource for the given record classes
  #
  # e.g., +most_recently_changed(WorkPackage, Type, Status)+
  #
  # Returns the timestamp of the most recently updated value
  def self.most_recently_changed(*record_classes)
    queries = record_classes.map do |clz|
      column_name = clz.send(:timestamp_attributes_for_update_in_model)&.first || "updated_at"
      table = clz.arel_table
      table.project(table[column_name].maximum.as("max_updated_at")).to_sql
    end
      .join(" UNION ")

    union_query = <<~SQL.squish
      SELECT MAX(max_updated_at)
      FROM (#{queries})
      AS union_query
    SQL

    ActiveRecord::Base.connection.select_value(union_query)
  end

  def self.human_model_name
    model_name.human
  end

  def self.human_plural_model_name(count: 2)
    model_name.human(count:)
  end

  # Returns all the attribute names as symbols.
  # @return [Array<Symbol>]
  def attribute_keys
    attribute_names.map(&:to_sym)
  end

  # Returns the keys of the attributes that have been changed.
  # @return [Array<Symbol>]
  def changed_attribute_keys
    changes.keys.map(&:to_sym)
  end

  # Returns the keys of the attributes that have been changed before the last save.
  # @return [Array<Symbol>]
  def changed_attribute_keys_before_last_save
    previous_changes.keys.map(&:to_sym)
  end
end
