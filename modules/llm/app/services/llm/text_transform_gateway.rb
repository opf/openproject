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

module Llm
  class TextTransformGateway < AI::TextTransforms::Gateway
    FEATURE = :description_assistant

    def readiness
      resolution = Llm::Runtime.for(FEATURE)
      Readiness.new(resolution.ready?, resolution.ready? ? nil : resolution.status)
    end

    def stream(system:, user:, timeout:, &)
      answer = chat(system:, timeout:).ask(user) { |chunk| forward(chunk, &) }
      text = answer.content.to_s
      raise AI::TextTransforms::Errors::Upstream, "empty completion" if text.strip.empty?

      text
    rescue Llm::Errors::Error => e
      raise e.cause if raised_by_consumer?(e.cause)

      raise translate(e)
    end

    private

    def chat(system:, timeout:)
      Llm::Runtime.for(FEATURE).chat(timeout:, max_retries: 0).with_instructions(system)
    end

    def forward(chunk)
      delta = chunk.content.to_s
      yield delta unless delta.empty?
    end

    def raised_by_consumer?(cause)
      cause.is_a?(AI::TextTransforms::Cancelled) || cause.is_a?(AI::TextTransforms::Errors::Error)
    end

    def translate(error)
      case error
      when Llm::Errors::NotReady, Llm::Errors::ConfigurationError
        AI::TextTransforms::Errors::NotAvailable.new(error.message)
      when Llm::Errors::TimeoutError
        AI::TextTransforms::Errors::TimedOut.new(error.message)
      when Llm::Errors::ConnectionError
        AI::TextTransforms::Errors::ConnectionFailed.new(error.message)
      else
        AI::TextTransforms::Errors::Upstream.new(error.message)
      end
    end
  end
end
