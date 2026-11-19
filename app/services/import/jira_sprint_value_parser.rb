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

module Import
  module JiraSprintValueParser
    SPRINT_FIELD_SCHEMA = "com.pyxis.greenhopper.jira:gh-sprint"

    STRING_FORM_KEYS = %w[activatedDate autoStartStop completeDate endDate goal id incompleteIssuesDestinationId
                          name rapidViewId sequence startDate state synced].freeze
    STRING_FORM = /\A[\w.$]+@\h+\[(?<attributes>.*)\]\z/m
    # Jira does not escape names and goals, so a comma only separates attributes when a known key follows it.
    STRING_FORM_SEPARATOR = /,(?=(?:#{STRING_FORM_KEYS.join('|')})=)/
    STRING_FORM_NULL = "<null>"
    STATES = %w[future active closed].freeze
    OPEN_STATES = %w[future active].freeze
    ID = /\A\d+\z/

    module_function

    # A key can occur more than once when a name or goal contains it, so each attribute takes the
    # first of its values that has the expected shape.
    def parse(value)
      attributes = attribute_values(value)
      return if attributes.nil?

      id = first_value(attributes, "id") { |candidate| candidate.to_s if candidate.to_s.match?(ID) }
      return if id.nil?

      {
        id:,
        state: first_value(attributes, "state") { |candidate| candidate.to_s.downcase.presence_in(STATES) },
        complete_date: first_value(attributes, "completeDate") { |candidate| parse_time(candidate) }
      }
    end

    def first_value(attributes, key, &)
      attributes.fetch(key, []).lazy.filter_map(&).first
    end

    def sprint_ids(field_value)
      Array.wrap(field_value).filter_map { |value| parse(value)&.dig(:id) }
    end

    # The value lists every sprint the issue was in, ordered by sprint sequence rather than
    # time. Jira keeps at most one open sprint in it.
    def current_sprint_id(field_value)
      sprints = Array.wrap(field_value).filter_map { |value| parse(value) }
      current = sprints.find { |sprint| OPEN_STATES.include?(sprint[:state]) } ||
                sprints.max_by { |sprint| sprint[:complete_date].to_i }
      current&.dig(:id)
    end

    def attribute_values(value)
      case value
      when Hash then value.stringify_keys.transform_values { |attribute| [attribute] }
      when String then string_form_attribute_values(value)
      end
    end

    def string_form_attribute_values(value)
      match = STRING_FORM.match(value)
      return if match.nil?

      match[:attributes]
        .split(STRING_FORM_SEPARATOR)
        .map { |pair| pair.split("=", 2) }
        .group_by(&:first)
        .transform_values { |pairs| pairs.map { |_key, attribute| attribute == STRING_FORM_NULL ? nil : attribute } }
    end

    def parse_time(value)
      Time.zone.parse(value.to_s) if value.present?
    rescue ArgumentError
      nil
    end

    def parse_date(value)
      Date.iso8601(value.to_s) if value.present?
    rescue ArgumentError
      nil
    end
  end
end
