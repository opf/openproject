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

module Interceptors
  module RateLimitEmails
    module_function

    def delivering_email(mail)
      recipient_count = [mail.to, mail.cc, mail.bcc].flatten.compact.uniq.size

      return if OpenProject::TokenBucketBasedRateLimiter::EmailLimitPerDay.consume!(recipient_count)

      mail.perform_deliveries = false
      report_dropped(mail, recipient_count)
    end

    def report_dropped(mail, recipient_count)
      OpenProject.logger.warn(
        "Dropped message due to daily email limit: '#{mail.subject}'",
        reference: :daily_email_limit,
        payload: {
          recipient_count: recipient_count,
          daily_limit: OpenProject::TokenBucketBasedRateLimiter::EmailLimitPerDay.limit,
          host_name: Setting.host_name
        }
      )

      OpenProject::OpenTelemetry.add_event(
        "outbound_mail.message_dropped",
        "openproject.mail.recipient_count" => recipient_count,
        "openproject.mail.daily_limit" => OpenProject::TokenBucketBasedRateLimiter::EmailLimitPerDay.limit
      )

      OpenProject::Appsignal.increment_counter(
        "outbound_mail.messages_dropped",
        1
      )
    end
  end
end
