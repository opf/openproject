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
  class SmtpDelivery < ::Mail::SMTP
    CONNECTION_ERRORS = [Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Net::OpenTimeout].freeze
    AUTO_SUBMITTED = "Auto-Submitted"

    def deliver!(mail)
      keep_own_auto_submitted(mail)
      *fallbacks, last = settings.fetch(:addresses)

      fallbacks.each do |address|
        settings[:address] = address
        return super
      rescue *CONNECTION_ERRORS => e
        Rails.logger.warn { "Connecting to #{address} failed (#{e.class.name}), trying the next address" }
      end

      settings[:address] = last
      super
    end

    private

    # Interceptors::DefaultHeaders adds "Auto-Submitted: auto-generated" and "Precedence: bulk" to every email,
    # next to the mailer's own Auto-Submitted. Other help desks drop emails marked automatic (RFC 3834),
    # so an email the mailer marked as not automatic must not carry either.
    def keep_own_auto_submitted(mail)
      return unless mail.header.fields.any? { it.name.casecmp?(AUTO_SUBMITTED) && it.value == "no" }

      mail[AUTO_SUBMITTED] = nil
      mail[AUTO_SUBMITTED] = "no"
      mail["Precedence"] = nil
    end

    def ssl_context = super.tap { it.min_version = MailServer::MIN_TLS_VERSION }
  end
end
