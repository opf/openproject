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

require "warden/basic_auth"

module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # Allows users to authenticate using their API key via basic auth.
        # Note that in order for a user to be able to generate one
        # `Setting.api_tokens_enabled` has to be `true`.
        #
        # The basic auth credentials are expected to contain the literal 'apikey'
        # as the user name and the API key as the password.
        class UserBasicAuth < ::Warden::Strategies::BasicAuth
          def self.user
            "apikey"
          end

          def valid?
            OpenProject::Configuration.apiv3_enable_basic_auth? &&
            super &&
            username == self.class.user
          end

          def authenticate_user(_, api_key)
            User.find_by_api_key api_key
          end
        end
      end
    end
  end
end
