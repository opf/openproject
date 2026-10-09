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
  module TextTransforms
    # Demo only (AI-126): what the result pane shows for a run, derived from the run's event log.
    class ResultPaneState
      SCOPES = %w[document selection].freeze
      REQUEST_ID = /\A[0-9a-f-]{36}\z/

      attr_reader :run, :scope, :request_id, :work_package, :context_ids, :rejection

      def self.rejected(message:, label:, scope:, request_id:, context_ids: {})
        new(run: nil, scope:, request_id:, label:, context_ids:, rejection: message)
      end

      def initialize(run:, scope:, request_id:, work_package: nil, context_ids: {}, label: nil, rejection: nil)
        @run = run
        @context_ids = context_ids
        @scope = SCOPES.include?(scope.to_s) ? scope.to_s : "document"
        @request_id = REQUEST_ID.match?(request_id.to_s) ? request_id.to_s : nil
        @work_package = work_package
        @label = label
        @rejection = rejection
      end

      def label
        @label || run&.action&.label.to_s
      end

      def state
        return "failed" if rejection

        case run.status
        when "succeeded" then "done"
        when "failed" then error_event&.payload&.dig("reason") == "blocked" ? "stopped" : "failed"
        when "cancelled" then "cancelled"
        else "generating"
        end
      end

      def text
        completed = events.reverse.find { |event| event.kind == "completed" }
        return completed.payload["text"].to_s if completed

        events.select { |event| event.kind == "text_delta" }.sum("") { |event| event.payload["delta"].to_s }
      end

      def error_message
        rejection || error_event&.payload&.dig("message") || run&.error_message
      end

      def last_seq
        events.last&.seq.to_i
      end

      def uuid
        run&.uuid || "rejected"
      end

      def selection?
        scope == "selection"
      end

      private

      def events
        @events ||= run ? run.events.order(:seq).to_a : []
      end

      def error_event
        events.reverse.find { |event| event.kind == "error" }
      end
    end
  end
end
