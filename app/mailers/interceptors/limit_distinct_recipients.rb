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
  # Allowing rate limiting the number of independent recipients an instance can mail to in any given day.
  module LimitDistinctRecipients
    FIELDS = %i[to cc bcc].freeze

    module_function

    def delivering_email(mail)
      return unless OpenProject::MailRecipientLimit.enabled?

      FIELDS.each { |field| drop_over_limit(mail, field) }
    end

    def drop_over_limit(mail, field)
      addresses = Array(mail.send(field))
      allowed = addresses.select { |address| OpenProject::MailRecipientLimit.allow?(address) }

      return if allowed.size == addresses.size

      dropped = addresses - allowed
      report_dropped(mail, field, dropped)
      mail.send(:"#{field}=", allowed)
    end

    def report_dropped(mail, field, dropped)
      OpenProject.logger.warn(
        "Dropped #{field} recipients over mail recipient limit from '#{mail.subject}': #{dropped.join(', ')}",
        reference: :mail_recipient_limit,
        payload: {
          field:,
          dropped_count: dropped.size,
          limit: OpenProject::MailRecipientLimit.limit,
          host_name: Setting.host_name
        }
      )

      OpenProject::OpenTelemetry.add_event(
        "outbound_mail.recipients_dropped",
        "openproject.mail.field" => field.to_s,
        "openproject.mail.dropped_count" => dropped.size,
        "openproject.mail.limit" => OpenProject::MailRecipientLimit.limit
      )

      OpenProject::Appsignal.increment_counter(
        "outbound_mail.recipients_dropped",
        dropped.size,
        field: field.to_s
      )
    end
  end
end
