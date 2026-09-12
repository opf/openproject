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
    class LlmGateway < Gateway
      FEATURE = :description_assistant

      def readiness
        resolution = Llm::Runtime.for(FEATURE)
        return Readiness.new(true, nil) if resolution.ready?

        Readiness.new(false, resolution.status)
      rescue OpenProject::Llm::UnknownFeature
        Readiness.new(false, :feature_unregistered)
      end

      def stream(system:, user:, timeout:, &)
        @cancelled = nil
        response = chat(system, timeout).ask(user) { |chunk| forward(chunk, &) }
        response.content.to_s
      rescue Cancelled
        raise
      rescue StandardError => e
        raise @cancelled if @cancelled

        raise translate(e)
      end

      private

      def chat(system, timeout)
        Llm::Runtime.for(FEATURE).chat(timeout:, max_retries: 0).with_instructions(system)
      end

      def forward(chunk)
        content = chunk.content
        return if content.to_s.empty?

        yield content
      rescue Cancelled => e
        @cancelled = e
        raise
      end

      def translate(error)
        Rails.logger.info { "AI text transform gateway failed: #{error.class}" }

        case error
        when Llm::Errors::TimeoutError
          Errors::TimedOut.new(error.class.name)
        when Llm::Errors::ConnectionError
          Errors::ConnectionFailed.new(error.class.name)
        when Llm::Errors::NotReady, Llm::Errors::ConfigurationError
          Errors::NotAvailable.new(error.class.name)
        else
          Errors::Upstream.new(error.class.name)
        end
      end
    end
  end
end
