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
  module Authentication
    class FailureApp
      attr_reader :failure_handlers

      def initialize(failure_handlers)
        @failure_handlers = failure_handlers
      end

      def call(env)
        warden = self.warden env
        scope = self.scope env

        if warden && warden.result == :failure
          handler = failure_handlers[scope] || default_failure_handler

          if handler
            handler.call warden, warden_options(env)
          else
            handle_failure warden
          end
        else
          unauthorized env
        end
      end

      def default_failure_handler
        failure_handlers[nil]
      end

      def handle_failure(warden)
        [warden.status || 401, warden.headers, [warden.message]]
      end

      def unauthorized(env)
        [401, unauthorized_header(env), ["unauthorized"]]
      end

      def warden(env)
        env["warden"]
      end

      def warden_options(env)
        Hash(env["warden.options"])
      end

      def unauthorized_header(env)
        header = OpenProject::Authentication::WWWAuthenticate.response_header(env:, scope: scope(env))

        { "WWW-Authenticate" => header }
      end

      def scope(env)
        warden_options(env)[:scope]
      end
    end
  end
end
