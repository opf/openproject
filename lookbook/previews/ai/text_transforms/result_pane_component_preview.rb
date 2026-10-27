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
    # @logical_path OpenProject/AI
    # @display min_height 640px
    class ResultPaneComponentPreview < Lookbook::Preview
      TEXT = <<~MARKDOWN
        The login page does not work in **Safari 17**. When I click *Submit*, nothing happens.

        Steps to reproduce:

        1. Open the login page in Safari 17.
        2. Enter valid credentials.
        3. Click *Submit*.
      MARKDOWN

      def generating
        render_pane(status: "running", events: [["text_delta", { "delta" => TEXT.first(60) }]])
      end

      def done
        render_pane(status: "succeeded", events: [["completed", { "text" => TEXT }]])
      end

      def done_with_long_text
        render_pane(status: "succeeded", events: [["completed", { "text" => ([TEXT] * 8).join("\n") }]])
      end

      def stopped
        render_pane(status: "failed", events: [["error", { "reason" => "blocked", "message" => "Blocked" }]])
      end

      def failed
        render_pane(status: "failed",
                    events: [["error", { "reason" => "timeout", "message" => I18n.t("ai.text_transform.errors.timeout") }]])
      end

      def cancelled
        render_pane(status: "cancelled", events: [])
      end

      def rejected
        pane = AI::TextTransforms::ResultPaneState.rejected(
          message: I18n.t("ai.text_transform.errors.not_available"),
          label: "Fix grammar",
          scope: "document",
          request_id: SecureRandom.uuid
        )
        render AI::TextTransforms::ResultPaneComponent.new(pane:)
      end

      private

      def render_pane(status:, events:, scope: "document")
        run = AI::TextTransformRun.new(status:, action: AI::TextTransformAction.new(label: "Fix grammar"))
        events.each.with_index(1) { |(kind, payload), seq| run.events.build(kind:, payload:, seq:) }
        pane = AI::TextTransforms::ResultPaneState.new(run:, scope:, request_id: SecureRandom.uuid)

        render AI::TextTransforms::ResultPaneComponent.new(pane:)
      end
    end
  end
end
