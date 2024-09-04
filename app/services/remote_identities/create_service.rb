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

module RemoteIdentities
  class CreateService
    attr_reader :user, :model

    def self.call(user:, oauth_config:, oauth_token:)
      new(user:, oauth_config:, oauth_token:).call
    end

    def initialize(user:, oauth_config:, oauth_token:)
      @user = user
      @oauth_config = oauth_config
      @oauth_token = oauth_token

      @model = RemoteIdentity.find_or_initialize_by(user:, oauth_client: oauth_config.oauth_client)
      @result = ServiceResult.success(result: @model, errors: @model.errors)
    end

    def call
      @model.origin_user_id = @oauth_config.extract_origin_user_id(@oauth_token)
      if @model.save
        emit_event(@oauth_config.oauth_client.integration)
      else
        @result.success = false
      end

      @result
    end

    def emit_event(integration)
      OpenProject::Notifications.send(
        OpenProject::Events::REMOTE_IDENTITY_CREATED,
        integration:
      )
    end
  end
end
