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

module RemoteIdentities
  class CreateService
    attr_reader :user, :model

    def self.call(user:, integration:, token:, force_update: false)
      new(user:, integration:, token:, force_update:).call
    end

    def initialize(user:, integration:, token:, force_update: false)
      @user = user
      @integration = integration
      @token = token
      @force_update = force_update

      @model = RemoteIdentity.find_or_initialize_by(user:, auth_source: token.auth_source, integration:)
    end

    def call
      if @model.new_record? || @force_update
        origin_result = @integration.extract_origin_user_id(@token)

        user_id = origin_result.value_or { return ServiceResult.failure(errors: it) }

        @model.origin_user_id = user_id
        return success unless @model.changed?
        return failure unless @model.save

        OpenProject::Notifications.send(
          OpenProject::Events::REMOTE_IDENTITY_CREATED,
          integration: @integration
        )
      end

      success
    end

    private

    def success
      ServiceResult.success(result: @model)
    end

    def failure
      ServiceResult.failure(result: @model, errors: @model.errors)
    end
  end
end
