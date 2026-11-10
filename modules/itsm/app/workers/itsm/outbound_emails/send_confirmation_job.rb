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

module ITSM
  module OutboundEmails
    class SendConfirmationJob < ApplicationJob
      include GoodJob::ActiveJobExtensions::Concurrency

      class DeliveryFailed < StandardError; end

      RETRIED_ERRORS = %i[delivery_failed unreachable].freeze

      queue_with_priority :notification

      good_job_control_concurrency_with(
        perform_limit: 1,
        key: -> { "#{self.class.name}-#{arguments.first.id}" }
      )

      retry_on DeliveryFailed, wait: :polynomially_longer, attempts: 10 do |job, _error|
        Rails.logger.warn { "Confirmation for email thread #{job.arguments.first.id} not sent after #{job.executions} attempts" }
      end

      discard_on ActiveJob::DeserializationError

      def perform(thread)
        Rails.logger.tagged("ITSM", "email thread #{thread.id}") do
          SendConfirmationService.new.call(thread:).on_failure { not_sent(it) }
        end
      end

      private

      def not_sent(result)
        codes = result.errors.symbols_for(:base)
        reason = "Confirmation not sent (#{(codes.presence || result.errors.attribute_names).join(', ')})"
        raise DeliveryFailed, reason if codes.intersect?(RETRIED_ERRORS)

        Rails.logger.info { reason }
      end
    end
  end
end
