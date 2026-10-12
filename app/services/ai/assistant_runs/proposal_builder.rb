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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module AssistantRuns
    # Turns the model's list of { field, value } into a stored proposal: Automations
    # actions with resolved values. A value that is not allowed, or that changes nothing,
    # is dropped.
    class ProposalBuilder
      def initialize(change_options)
        @change_options = change_options
      end

      def build(raw_changes)
        actions = Array(raw_changes).each_with_object({}) do |raw, result|
          raw = raw.to_h.stringify_keys
          key = raw["field"].to_s
          value = @change_options.resolve(key, key == "subject" ? raw["value"].to_s.truncate(255) : raw["value"])
          next if value.nil? || result.key?(key) || value == current_value(key)

          result[key] = value
        end
        AI::Proposal.change_set_for(actions) if actions.any?
      end

      # The answer schema for a list of changes, limited to the fields that are allowed.
      def schema
        {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: %w[field value],
            properties: {
              field: { type: "string", enum: @change_options.keys.presence || ["none"] },
              value: { type: "string" }
            }
          }
        }
      end

      private

      def current_value(key)
        work_package = @change_options.work_package
        case key
        when "comment" then nil
        when "status", "priority", "assigned_to", "responsible" then work_package.public_send(:"#{key}_id").to_s
        when "start_date", "due_date" then work_package.public_send(key)&.iso8601
        else work_package.public_send(key).to_s
        end
      end
    end
  end
end
