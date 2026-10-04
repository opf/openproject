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
  module Authentication
    class Manager < Warden::Manager
      serialize_into_session(&:id)

      serialize_from_session do |id|
        User.find id
      end

      def initialize(app, options = {}, &configure)
        block = lambda { |config|
          self.class.configure_warden config

          yield config if configure
        }

        super(app, options, &block)
      end

      class << self
        def config
          @config ||= Hash.new
        end

        def scope_config(scope)
          config[scope] ||= ScopeSettings.new
        end

        def failure_handlers
          @failure_handlers ||= {}
        end

        def auth_scheme(name)
          auth_schemes[name] ||= AuthSchemeInfo.new
        end

        def auth_schemes
          @auth_schemes ||= {}
        end

        def configure_warden(warden_config)
          warden_config.default_strategies :session
          warden_config.failure_app = OpenProject::Authentication::FailureApp.new failure_handlers

          config.each do |scope, cfg|
            warden_config.scope_defaults scope, strategies: cfg.strategies, store: cfg.store
          end
        end
      end

      class ScopeSettings
        attr_accessor :store, :strategies, :realm

        def initialize
          @store = true
          @strategies = Set.new
        end

        def update!(opts, &block)
          self.store = opts[:store] if opts.include? :store
          self.realm = opts[:realm] if opts.include? :realm
          self.strategies = yield strategies if block
        end
      end

      class AuthSchemeInfo
        attr_accessor :strategies

        def initialize
          @strategies = Set.new
        end
      end
    end
  end
end
