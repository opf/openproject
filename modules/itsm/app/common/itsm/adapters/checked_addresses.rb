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
  module Adapters
    class CheckedAddresses
      include Dry::Monads::Result(SimpleError)

      def self.call(host) = new.call(host)

      def call(host)
        addresses = OpenProject::SsrfProtection.resolver.call(host)

        return failure(:unreachable) if addresses.empty?
        return failure(:address_not_allowed) unless addresses.all? { OpenProject::SsrfProtection.safe_ip?(it) }

        Success(addresses.map(&:to_s))
      end

      private

      def failure(code) = Failure(SimpleError.new(source: self.class, code:))
    end
  end
end
