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

module AI
  module TextTransforms
    class ResultPaneState
      attr_reader :run, :scope, :request_id, :work_package, :context_ids, :rejection

      def self.rejected(message:, label:, scope:, request_id:, context_ids: {})
        new(run: nil, scope:, request_id:, label:, context_ids:, rejection: message)
      end

      def initialize(run:, scope:, request_id:, work_package: nil, context_ids: {}, label: nil, rejection: nil)
        @run = run
        @scope = scope
        @request_id = request_id
        @work_package = work_package
        @context_ids = context_ids
        @label = label
        @rejection = rejection
      end

      def label
        (@label || run&.action&.label).to_s
      end

      def state
        @state ||= run ? run_state : "failed"
      end

      def text
        @text ||= completed_event ? completed_event.payload["text"].to_s : streamed_text
      end

      def error_message
        rejection.presence ||
          error_event&.payload&.dig("message").presence ||
          run&.error_message.presence ||
          I18n.t("ai.text_transform.errors.upstream_error")
      end

      def last_seq
        events.last&.seq.to_i
      end

      def uuid
        run&.uuid || "rejected"
      end

      private

      def events
        @events ||= run ? run.events.sort_by(&:seq) : []
      end

      def run_state
        case run.status
        when "succeeded" then "done"
        when "failed" then blocked? ? "stopped" : "failed"
        when "cancelled" then "cancelled"
        else "generating"
        end
      end

      def completed_event
        events.reverse_each.find { |event| event.kind == "completed" }
      end

      def streamed_text
        events.select { |event| event.kind == "text_delta" }.map { |event| event.payload["delta"] }.join
      end

      def error_event
        return @error_event if defined?(@error_event)

        @error_event = events.reverse_each.find { |event| event.kind == "error" }
      end

      def blocked?
        error_event&.payload&.dig("reason") == "blocked"
      end
    end
  end
end
