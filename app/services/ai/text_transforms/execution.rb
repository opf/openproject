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
    class Execution
      FLUSH_INTERVAL = 0.5
      BUDGET = 180
      MONOTONIC_CLOCK = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }

      def initialize(run, gateway: Gateway.build, clock: MONOTONIC_CLOCK)
        @run = run
        @gateway = gateway
        @clock = clock
        @buffer = +""
      end

      def call
        perform_run
      rescue Cancelled
        finish("cancelled")
      rescue Errors::Error => e
        fail_run(e.reason)
      rescue ActiveRecord::InvalidForeignKey
        raise if AI::TextTransformRun.exists?(run.id)
      rescue StandardError
        fail_run(:upstream_error)
        raise
      end

      private

      attr_reader :run, :gateway, :clock, :buffer

      def perform_run
        return fail_run(:not_available) unless Availability.new(gateway:).runnable(run.action).available?

        run.start!
        record("status", status: "running")
        text = stream
        flush
        record("completed", text:)
        run.finish!("succeeded")
      end

      def stream
        @started = @last_flush = clock.call

        gateway.stream(system: run.system_prompt, user: run.input, timeout: BUDGET) { |delta| receive(delta) }
      end

      def receive(delta)
        buffer << delta
        return if clock.call - @last_flush < FLUSH_INTERVAL

        raise Cancelled unless still_wanted?

        flush
        @last_flush = clock.call
        raise Errors::TimedOut, "budget exceeded" if clock.call - @started > BUDGET
      end

      def flush
        return if buffer.empty?

        record("text_delta", delta: buffer.dup)
        buffer.clear
      end

      def still_wanted?
        current = AI::TextTransformRun.find_by(id: run.id)
        current.present? && !current.cancel_requested?
      end

      def record(kind, payload)
        event = run.append_event(kind, payload)
        Rails.logger.debug { "AI run #{run.uuid}: #{event.kind} ##{event.seq}" }
      end

      def finish(status)
        return unless AI::TextTransformRun.exists?(run.id)

        run.finish!(status)
      end

      def fail_run(reason)
        return unless AI::TextTransformRun.exists?(run.id)

        message = OpenProject::LocaleHelper.with_locale_for(run.user) do
          I18n.t("ai.text_transform.errors.#{reason}")
        end
        record("error", message:, reason: reason.to_s)
        run.finish!("failed", error_message: message)
      end
    end
  end
end
