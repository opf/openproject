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
        ##
        # Allows authentication via a singular set of basic auth credentials for admin access.
        #
        # The credentials must be configured in `config/configuration.yml` like this:
        #
        #     production:
        #       authentication:
        #         global_basic_auth:
        #           user: admin
        #           password: 123456
        #
        # The strategy will only be triggered when the configured user name is sent.
        # Meaning that this strategy is skipped if a basic auth attempt involving any
        # other user name is made.
        class GlobalBasicAuth < ::Warden::Strategies::BasicAuth
          def self.configuration
            @configuration ||= configure!
          end

          ##
          # Updates the configuration for this strategy. It's usually called only once, at startup.
          #
          # @param [Hash] config The configuration to be used. Must contain :user and :password.
          # @raise [ArgumentError] Raises an error if the configured user name collides with the
          #                        user name used for UserBasicAuth (apikey) or if the
          #                        provided password is empty.
          # @return [Hash] The new hash set for the configuration or an empty hash if
          #                no configuration was provided.
          def self.configure!(config = openproject_config)
            return {} if config.empty?

            if config[:user] == UserBasicAuth.user
              raise ArgumentError, "global user must not be '#{UserBasicAuth.user}'"
            end

            if config[:password].blank?
              raise ArgumentError, "password must not be empty"
            end

            @configuration = config
          end

          ##
          # Reads the configuration for this strategy from OpenProject's `configuration.yml`.
          def self.openproject_config
            config = OpenProject::Configuration
            %w(authentication global_basic_auth).inject(config) do |acc, key|
              ActiveSupport::HashWithIndifferentAccess.new acc[key]
            end
          end

          def self.configuration?
            user && password
          end

          def self.user
            configuration[:user]
          end

          def self.password
            configuration[:password].to_s
          end

          ##
          # Only valid if global basic auth is configured and tried.
          def valid?
            OpenProject::Configuration.apiv3_enable_basic_auth? &&
            self.class.configuration? &&
            super &&
            username == self.class.user
          end

          def authenticate_user(username, password)
            if username == self.class.user && password == self.class.password
              User.system
            end
          end
        end
      end
    end
  end
end
