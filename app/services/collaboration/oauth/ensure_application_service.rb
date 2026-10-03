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

module Collaboration
  module OAuth
    ##
    # Service to ensure the existence of the OAuth application shared by all collaborative resources.
    # Name and UID predate the extraction from the documents module and are kept for existing installations.
    #
    # This service is responsible for finding or creating a Doorkeeper OAuth application
    # that is used for authenticating the YJS provider with the OpenProject API.
    # The application is created as a confidential client with API v3 scope.
    class EnsureApplicationService < BaseServices::BaseCallable
      APPLICATION_NAME = "Documents OAuth Application"
      APPLICATION_UID = "documents_yjs_provider"

      def perform
        application = find_or_create_application

        if application.persisted?
          ServiceResult.success(result: application)
        else
          ServiceResult.failure(errors: application.errors)
        end
      end

      private

      def find_or_create_application
        existing = Doorkeeper::Application.find_by(uid: APPLICATION_UID)
        return existing if existing

        create_application
      end

      def create_application
        result = ::OAuth::Applications::CreateService
          .new(user: User.system)
          .call(
            uid: APPLICATION_UID,
            name: APPLICATION_NAME,
            redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
            scopes: "api_v3",
            confidential: true,
            owner: User.system
          )

        result.result
      end
    end
  end
end
