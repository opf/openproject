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
  module InboundEmails
    ThreadAttributes = Data.define(:requester_email, :requester_name, :recipients) do
      def self.from_email(email)
        new(requester_email: email.headers.from_address, requester_name: email.headers.from_name, recipients: recipients(email))
      end

      def self.recipients(email)
        headers = email.headers

        EmailAddress::NORMALIZE_ALL.call(headers.to_addresses + headers.cc_addresses) -
          [EmailAddress::NORMALIZE.call(headers.from_address)] - own_addresses
      end

      def self.own_addresses
        IncomingMailbox.pluck(:email, :aliases).flatten + OutgoingMailbox.pluck(:sender_email)
      end

      private_class_method :recipients, :own_addresses
    end
  end
end
