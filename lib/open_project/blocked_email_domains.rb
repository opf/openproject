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

module OpenProject
  # Email domains that may not be used for user accounts, configured through the
  # `blocked_email_domains` setting. Setting it in configuration.yml or through an
  # environment variable makes it read only for administrators.
  module BlockedEmailDomains
    class << self
      # Pass `domains:` to check many addresses against one read of the setting.
      def blocked?(email, domains: self.domains)
        domain = domain_of(email)

        return false if domain.blank?

        domains.any? { |blocked| domain == blocked || domain.end_with?(".#{blocked}") }
      end

      def domains
        normalize Setting.blocked_email_domains
      end

      def domain_of(email)
        local, domain = email.to_s.rpartition("@").values_at(0, 2)

        domain.strip.downcase.presence if local.present?
      end

      private

      def normalize(domains)
        list = domains.is_a?(String) ? domains.split(/[\s,]+/) : Array(domains)

        list.filter_map do |domain|
          domain.to_s.strip.downcase.delete_prefix("@").delete_prefix(".").presence
        end
      end
    end
  end
end
