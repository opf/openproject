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
  class HelpdeskMailer < ActionMailer::Base # rubocop:disable Rails/ApplicationMailer -- ApplicationMailer only sends to users
    class_attribute :mailbox_delivery_method, default: :smtp

    def confirmation(email_message, mailbox, address)
      @thread = email_message.thread
      @work_package = @thread.work_package

      message = I18n.with_locale(Setting.default_language) { mail(email_attributes(email_message)) }

      # ActionMailer would merge the instance's SMTP settings (TLS flags, certificate verification) into the mailbox's.
      # Delivery errors are disabled globally in development, but the sender has to know whether the email was sent.
      message.delivery_method(mailbox_delivery_method, mailbox.smtp_settings(address))
      message.raise_delivery_errors = true
    end

    private

    def email_attributes(email_message)
      {
        from: email_address_with_name(email_message.from_address, email_message.from_name),
        to: email_message.to_addresses,
        cc: email_message.cc_addresses,
        subject: email_message.subject,
        message_id: email_message.message_id,
        in_reply_to: email_message.in_reply_to,
        references: email_message.referenced_message_ids.presence
      }
    end
  end
end
