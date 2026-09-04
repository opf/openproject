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
  # Removes recipients on a domain listed in the `blocked_email_domains` setting.
  # The validation on User only applies to addresses as they are entered, so this
  # covers users whose domain was blocked after their account already existed.
  #
  # Mails left without any recipient are dropped by DoNotSendMailsWithoutRecipient,
  # which is why this has to run before it.
  module RemoveBlockedRecipients
    FIELDS = %i[to cc bcc].freeze

    module_function

    def delivering_email(mail)
      domains = ::OpenProject::BlockedEmailDomains.domains

      return if domains.empty?

      FIELDS.each { |field| remove_blocked(mail, field, domains) }
    end

    def remove_blocked(mail, field, domains)
      addresses = Array(mail.send(field))
      allowed = addresses.reject { |address| ::OpenProject::BlockedEmailDomains.blocked?(address, domains:) }

      return if allowed.size == addresses.size

      Rails.logger.info do
        "Removed blocked #{field} recipients from '#{mail.subject}': #{(addresses - allowed).join(', ')}"
      end

      mail.send(:"#{field}=", allowed)
    end
  end
end
