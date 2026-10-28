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
  module Assistance
    # The values a proposal may set on one work package for one user: the attributes the
    # skill may change (the admin's choice), with the values that are valid now
    # (workflow, assignable users). The model
    # gets the names; answers are mapped back to ids here, so the model never invents ids.
    class ChangeOptions
      TEXT_KEYS = %w[subject description comment].freeze
      DATE_KEYS = %w[start_date due_date].freeze
      ASSOCIATION_KEYS = %w[status priority assigned_to responsible].freeze
      # The work package attributes a skill can propose changes to; a comment comes on top.
      ATTRIBUTE_KEYS = (%w[subject description] + ASSOCIATION_KEYS + DATE_KEYS).freeze

      attr_reader :work_package, :user

      # keys: the attributes the caller may change, for example a skill's changeable attributes.
      def initialize(keys:, work_package:, user:)
        @allowed_keys = Array(keys).map(&:to_s)
        @work_package = work_package
        @user = user
      end

      def keys
        @allowed_keys & (TEXT_KEYS + DATE_KEYS + ASSOCIATION_KEYS)
      end

      # For the message to the model: { "status" => ["In progress", "Closed"], "due_date" => "ISO date", ... }
      def for_prompt
        keys.index_with do |key|
          if TEXT_KEYS.include?(key) then "text"
          elsif DATE_KEYS.include?(key) then "ISO date (YYYY-MM-DD)"
          else options(key).map(&:last)
          end
        end
      end

      # The value to store in the action for the model's answer, or nil when it is not allowed.
      def resolve(key, answer)
        key = key.to_s
        answer = answer.to_s.strip
        return if answer.empty? || keys.exclude?(key)

        if TEXT_KEYS.include?(key) then answer
        elsif DATE_KEYS.include?(key) then iso_date(answer)
        else option_id(key, answer)
        end
      end

      # Whether a stored value is still allowed: checked again when the user applies it.
      def allowed?(key, value)
        key = key.to_s
        return false if keys.exclude?(key)
        return true unless ASSOCIATION_KEYS.include?(key)

        options(key).any? { |id, _name| id.to_s == value.to_s }
      end

      # The label of a value, for the dialog.
      def label(key, value)
        return value.to_s unless ASSOCIATION_KEYS.include?(key.to_s)

        record = association_scope(key.to_s)&.find_by(id: value)
        record&.name || value.to_s
      end

      private

      def option_id(key, name)
        options(key).find { |_id, option_name| option_name.casecmp?(name) }&.first&.to_s
      end

      def options(key)
        @options ||= {}
        @options[key] ||= valid_now(key).map { |r| [r.id, r.name] }
      end

      def valid_now(key)
        contract = WorkPackages::UpdateContract.new(work_package, user)
        case key
        when "status" then contract.assignable_statuses
        when "priority" then contract.assignable_priorities
        when "assigned_to" then contract.assignable_assignees
        when "responsible" then contract.assignable_responsibles
        else []
        end
      end

      def association_scope(key)
        case key
        when "status" then Status
        when "priority" then IssuePriority
        when "assigned_to", "responsible" then Principal
        end
      end

      def iso_date(answer)
        Date.iso8601(answer).iso8601
      rescue Date::Error
        nil
      end
    end
  end
end
