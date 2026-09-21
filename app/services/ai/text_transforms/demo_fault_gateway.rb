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
    # Demo only (AI-126): lets the result popover show its "stopped" and "failed"
    # states on demand. The real signal of a guardrail that blocks a stream is
    # unknown, so it is simulated on top of the real gateway.
    class DemoFaultGateway < Gateway
      FAULTS = %w[blocked failed].freeze
      MARKER = /\n\n\[\[demo-fault:(#{FAULTS.join('|')})\]\]\z/
      BLOCK_AFTER = 2

      def self.mark(system_prompt, fault)
        FAULTS.include?(fault) ? "#{system_prompt}\n\n[[demo-fault:#{fault}]]" : system_prompt
      end

      def initialize(gateway)
        super()
        @gateway = gateway
      end

      delegate :readiness, to: :gateway

      def stream(system:, user:, timeout:, &)
        fault = system[MARKER, 1]
        system = system.sub(MARKER, "")
        raise Errors::ConnectionFailed, "demo fault" if fault == "failed"
        return gateway.stream(system:, user:, timeout:, &) unless fault == "blocked"

        stream_until_blocked(system:, user:, timeout:, &)
      end

      private

      attr_reader :gateway

      def stream_until_blocked(system:, user:, timeout:)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        gateway.stream(system:, user:, timeout:) do |delta|
          raise Errors::Blocked, "demo fault" if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started > BLOCK_AFTER

          yield delta
        end

        raise Errors::Blocked, "demo fault"
      end
    end
  end
end
