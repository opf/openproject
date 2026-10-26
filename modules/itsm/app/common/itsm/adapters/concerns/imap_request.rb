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
    module Concerns
      module ImapRequest
        include Dry::Monads[:result]

        private

        def imap_request(source: self.class)
          Success(yield)
        rescue OpenSSL::SSL::SSLError => e
          failure(code: :tls_failed, payload: e.message, source:)
        rescue SocketError, SystemCallError, IOError, Timeout::Error => e
          failure(code: :unreachable, payload: e.message, source:)
        rescue Net::IMAP::Error => e
          failure(code: :server_error, payload: e.message, source:)
        end

        def failure(code:, payload: nil, source: self.class)
          Failure(SimpleError.new(source:, code:, payload:))
        end
      end
    end
  end
end
