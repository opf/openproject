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

class Source::SeedData
  def initialize(data, registry = nil)
    @data = data
    @registry = registry || {}
  end

  def store_reference(reference, record)
    return if reference.nil?
    if reference_exists?(reference)
      raise ArgumentError, "an object with reference #{reference.inspect} is already registered"
    end

    registry[reference] = record
  end

  # Finds and returns the value associated with the given reference.
  #
  # @param reference [Symbol] The reference to search for.
  # @param fallbacks [Array<Symbol>] Optional fallback references to search for if the primary reference is not found.
  # @param default [Object] The default value to return if no reference or fallbacks are found.
  # @return [Object, nil] The value associated with the reference, or nil if the reference is nil.
  # @raise [ArgumentError] If no reference or fallbacks are found and no default value is provided.
  def find_reference(reference, *fallbacks, default: :__unset__)
    return if reference.nil?

    existing_ref = [reference, *fallbacks].find { |ref| reference_exists?(ref) }
    if existing_ref
      registry[existing_ref]
    elsif default != :__unset__
      default
    else
      references = [reference, *fallbacks].map(&:inspect)
      message = "Nothing registered with #{'reference'.pluralize(references.count)} #{references.to_sentence(locale: false)}"
      if Rails.env.local?
        message += "\nPerhaps you forgot to add the `attribute_names_for_lookups` for your seeder?"
      end
      raise ArgumentError, message
    end
  end

  def find_references(references, default: :__unset__)
    Array(references).map { |reference| find_reference(reference, default:) }
  end

  def reference_exists?(reference)
    registry.key?(reference)
  end

  def all_references_exist?(references)
    references.all? { |reference| reference_exists?(reference) }
  end

  # Get a `SeedData` instance with only the given top level keys.
  #
  # Used in tests to get the real statuses, types and other data.
  def only(*keys)
    self.class.new(data.slice(*keys), registry.dup)
  end

  # Returns a new `SeedData` instance with its data and its registry merged with
  # the ones from the given instance.
  #
  # The data from the given instance takes precedence for keys present in both
  # instances.
  def merge(other)
    self.class.new(data.merge(other.data), registry.merge(other.registry))
  end

  def lookup(path)
    case sub_data = fetch(path)
    when Hash
      self.class.new(sub_data, registry)
    else
      sub_data
    end
  end

  def each(path, &)
    case sub_data = fetch(path)
    when nil
      nil
    when Enumerable
      sub_data.each(&)
    else
      raise ArgumentError, "expected an Enumerable at path #{path}, got #{sub_data.class}"
    end
  end

  def each_data(path)
    sub_data = fetch(path)
    return to_enum(:each_data, path) unless block_given? || sub_data.nil?

    sub_data.each_value do |item_data|
      yield self.class.new(item_data, registry)
    end
  end

  protected

  attr_reader :data, :registry

  def fetch(path)
    keys = path.to_s.split(".")
    data.dig(*keys)
  end
end
