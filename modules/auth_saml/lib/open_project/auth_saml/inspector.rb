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

module OpenProject
  module AuthSaml
    module Inspector
      module_function

      def inspect_response(auth_hash)
        response = auth_hash.dig(:extra, :response_object)
        if response
          code = response.status_code ? "(CODE #{response.status_code})" : nil
          message = response.status_message ? "(MESSAGE #{response.status_code})" : nil
          yield "SAML response success ?  #{response.success?} #{code} #{message}"

          errors = Array(response.errors).map(&:to_s).join(", ")
          yield "SAML errors: #{errors}" if errors.present?

          yield "SAML response XML: #{response.response || '(not present)'}"
        end
        uid = auth_hash[:uid]
        yield "SAML response uid (name identifier): #{uid || '(not present)'}"

        info = auth_hash[:info]
        yield "SAML retrieved attributes: #{info.inspect}"

        yield "SAML auth hash is invalid, attributes are missing." unless auth_hash.valid?

        session_idx = auth_hash.dig(:extra, :session_index)
        yield "SAML session index: #{session_idx}"
      end
    end
  end
end
