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
    # The "Details" part of a run or a chat answer: what happened, when, and what was sent
    # to and received from the model. Only the user it belongs to sees it. Error
    # messages can name servers, so only admins see them.
    class RunEventsComponent < ApplicationComponent
      ICONS = { "request" => :"arrow-up", "answer" => :"arrow-down", "tool_call" => :tools, "thought" => :comment,
                "stored" => :check, "failure" => :alert }.freeze

      attr_reader :events

      # events: the entries of a chat answer ({at, kind, data}).
      def initialize(events:)
        super
        @events = Array(events)
      end

      def render?
        events.any?
      end

      def icon(event)
        ICONS.fetch(event["kind"], :dot)
      end

      def time(event)
        helpers.format_time(Time.zone.parse(event["at"]), include_date: false)
      rescue ArgumentError, TypeError
        event["at"]
      end

      def summary(event)
        data = event["data"]
        case event["kind"]
        when "request"
          I18n.t("ai_assistance.events.request", model: data["model"],
                                                 system: data["system"].to_s.size, message: data["message"].to_s.size)
        when "answer"
          answer_summary(data)
        when "tool_call"
          tool_call_summary(data)
        when "stored"
          I18n.t("ai_assistance.events.stored", stored: data["stored"], findings: data["findings"],
                                                dropped: Array(data["dropped"]).size)
        when "failure"
          I18n.t("ai_assistance.events.failure", error: data["error"].to_s.demodulize)
        else
          other_summary(event["kind"])
        end
      end

      def other_summary(kind)
        I18n.t("ai_assistance.events.#{kind}", default: kind)
      end

      # Blocks the user can open: the texts the model got and gave.
      def blocks(event)
        data = event["data"]
        case event["kind"]
        when "request"
          { I18n.t("ai_assistance.events.system_prompt") => data["system"],
            I18n.t("ai_assistance.events.message") => pretty_json(data["message"]) }
        when "answer"
          { I18n.t("ai_assistance.events.raw_answer") => data["content"] }
        when "tool_call"
          tool_call_blocks(data)
        when "thought"
          { I18n.t("ai_assistance.events.thought_text") => data["text"] }
        when "stored"
          dropped = Array(data["dropped"])
          dropped.any? ? { I18n.t("ai_assistance.events.dropped") => JSON.pretty_generate(dropped) } : {}
        when "failure"
          User.current.admin? ? { I18n.t("ai_assistance.events.error") => data["message"] } : {}
        else
          {}
        end.compact_blank
      end

      private

      def tool_call_blocks(data)
        { I18n.t("ai_assistance.events.arguments") => JSON.pretty_generate(data["arguments"] || {}),
          I18n.t("ai_assistance.events.result") => data["result"] }
      end

      def answer_summary(data)
        count = data["tool_calls"].to_i
        return I18n.t("ai_assistance.events.answer", seconds: data["seconds"]) if count.zero?

        I18n.t("ai_assistance.events.answer_with_tools", seconds: data["seconds"], count:)
      end

      def tool_call_summary(data)
        name = data["name"]
        if data["error"] then I18n.t("ai_assistance.events.tool_call_failed", name:, error: data["error"].to_s.demodulize)
        elsif data["refused"] then I18n.t("ai_assistance.events.tool_call_refused", name:)
        elsif data["repeated"] then I18n.t("ai_assistance.events.tool_call_repeated", name:)
        else I18n.t("ai_assistance.events.tool_call", name:, seconds: data["seconds"], size: data["size"])
        end
      end

      def pretty_json(text)
        JSON.pretty_generate(JSON.parse(text.to_s))
      rescue JSON::ParserError
        text
      end
    end
  end
end
