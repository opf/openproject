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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
# frozen_string_literal: true

module FieldRules
  EffectiveField = Data.define(:key, :hidden, :required, :read_only, :default_value, :enforce_on_update, :source) do
    def self.from_rule(rule)
      new(key: rule.field_key,
          hidden: rule.hidden,
          required: rule.required && !rule.hidden,
          read_only: rule.read_only && !rule.hidden,
          default_value: rule.default_value,
          enforce_on_update: rule.enforce_on_update,
          source: :rule_set)
    end

    def restricts_writes? = hidden || read_only
  end

  class EffectiveConfiguration
    include Enumerable

    attr_reader :fields

    def self.empty = @empty ||= new({})

    def self.from_rules(rules)
      new(rules.to_h { |rule| [rule.field_key, EffectiveField.from_rule(rule)] })
    end

    def initialize(fields = {})
      @fields = fields.freeze
      freeze
    end

    def [](key) = fields[key.to_s]
    def each(&) = fields.each_value(&)
    def empty? = fields.empty?
    def keys = fields.keys

    def hidden?(key) = self[key]&.hidden || false
    def required?(key) = self[key]&.required || false
    def read_only?(key) = self[key]&.read_only || false
    def editable?(key) = !(hidden?(key) || read_only?(key))

    def restricting_write(attribute)
      select(&:restricts_writes?).any? { |field| Fields.attribute_matches?(field.key, attribute) }
    end

    # Requirements a workflow transition might impose, e.g. { "priority" => :required }.
    def conflicts_with(requirements)
      requirements.filter_map do |key, requirement|
        field = self[key]
        next unless field

        { field: key.to_s, requirement:, state: :hidden } if requirement == :required && field.hidden
      end
    end
  end
end
