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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module Assistance
    # The tool calls of one answer: each one is logged as a "tool_call" event, an identical call
    # gets the earlier result, and the number is limited. RubyLLM itself has no limit.
    class ToolCalls
      SOFT_LIMIT = 20
      HARD_LIMIT = 25
      # A model that repeats a call after the note usually loops: the next one answers now.
      MAX_REPEATS = 1
      LIMIT_TEXT = "No more tool calls. Answer now with what you have."
      REPEATED_TEXT = "You already called this tool with these arguments. Use this result:"
      ERROR_TEXT = { error: "The tool failed. Check the arguments against the tool's schema." }.to_json

      # Passes Llm::Errors.wrap unchanged, so the answer fails with this error.
      class Exceeded < Llm::Errors::Error; end

      attr_reader :count

      def initialize(llm_call)
        @llm_call = llm_call
        @count = 0
        @repeats = 0
        @results = {}
      end

      def run(name, args, &)
        @count += 1
        raise Exceeded, "more than #{HARD_LIMIT} tool calls" if @count > HARD_LIMIT
        return refuse(name, args) if @count > SOFT_LIMIT || @repeats >= MAX_REPEATS

        key = [name, args.sort.to_h].to_json
        return repeat(name, args, @results[key]) if @results.key?(key)

        @results[key] = perform(name, args, &)
      end

      private

      def perform(name, args)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        text = yield
        seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)
        record(name, args, seconds:, size: text.size, result: text)
        @llm_call.log(:info, "tool #{name} in #{seconds}s, #{text.size}c")
        text
      rescue StandardError => e
        record(name, args, error: e.class.name)
        @llm_call.log(:warn, "tool #{name} failed: #{e.class}: #{e.message}")
        ERROR_TEXT
      end

      def refuse(name, args)
        record(name, args, refused: true)
        LIMIT_TEXT
      end

      def repeat(name, args, text)
        @repeats += 1
        record(name, args, repeated: true)
        "#{REPEATED_TEXT}\n#{text}"
      end

      def record(name, args, **data)
        @llm_call.record.log_event(:tool_call, name:, arguments: args, **data)
      end
    end
  end
end
