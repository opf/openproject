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

module Import
  module Jiras
    module Validators
      class ConfigurationValidator < HealthReports::ValidatorGroup
        CREDENTIALS = {
          "bearer" => %i[personal_access_token],
          "basic" => %i[basic_auth_username basic_auth_password]
        }.freeze

        def self.key = :configuration

        private

        def validate
          register_checks(:url_valid, :credentials_present)
          check_url_valid
          check_credentials_present
        end

        def check_url_valid
          return pass_check(:url_valid) if subject.http_url?

          fail_check(:url_valid, :invalid_url)
        end

        def check_credentials_present
          return pass_check(:credentials_present) if missing_credential.nil?

          fail_check(:credentials_present, :"#{missing_credential}_missing")
        end

        def missing_credential
          CREDENTIALS.fetch(subject.auth_method).find { |credential| subject.public_send(credential).blank? }
        end
      end
    end
  end
end
