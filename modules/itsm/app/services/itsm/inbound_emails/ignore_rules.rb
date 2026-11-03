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
    class IgnoreRules
      AUTOMATIC_HEADERS = %w[Auto-Submitted X-Autoreply X-Autorespond List-Unsubscribe].freeze
      PRECEDENCE_HEADERS = %w[Precedence X-Precedence].freeze
      BULK_PRECEDENCES = %w[auto_reply bulk junk list].freeze

      def initialize(email)
        @email = email
      end

      def reason
        if sent_by_openproject? then :sent_by_openproject
        elsif sent_by_helpdesk? then :sent_by_helpdesk
        elsif automatic? then :automatic
        end
      end

      private

      attr_reader :email

      def sent_by_openproject? = email.header_value("X-OpenProject-Host") == Setting.host_name

      def sent_by_helpdesk? = EmailAddress.helpdesk_addresses.include?(email.headers.from_address)

      def automatic? = email.delivery_report? || automatic_header? || bulk_precedence?

      def automatic_header?
        AUTOMATIC_HEADERS.any? { |name| email.header_value(name).then { it.present? && !it.casecmp?("no") } }
      end

      def bulk_precedence?
        PRECEDENCE_HEADERS.any? { |name| BULK_PRECEDENCES.include?(email.header_value(name).to_s.strip.downcase) }
      end
    end
  end
end
