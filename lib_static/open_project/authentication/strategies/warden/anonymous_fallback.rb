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

require "warden/basic_auth"

module OpenProject
  module Authentication
    module Strategies
      module Warden
        # Intended to be used as the last strategy in warden so that the
        # anonymous user is returned if no other strategy applies
        class AnonymousFallback < ::Warden::Strategies::BasicAuth
          def self.configuration
            @configuration ||= {}
          end

          def self.user
            User.anonymous
          end

          def username
            nil
          end

          def password
            nil
          end

          ##
          # Always valid unless session based. We are using it as a fallback after all.
          def valid?
            session&.id.nil?
          end

          def authenticate_user(_username, _password)
            self.class.user
          end

          private

          def session
            env["rack.session"]
          end
        end
      end
    end
  end
end
