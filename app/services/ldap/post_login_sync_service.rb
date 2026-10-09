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

module Ldap
  class PostLoginSyncService < BaseService
    attr_reader :user, :update_attributes

    def initialize(ldap, user:, attributes:)
      super(ldap)

      @user = user
      @update_attributes = attributes
    end

    private

    def perform
      synchronize_user_attributes(user, update_attributes)
    rescue StandardError => e
      Rails.logger.error { "Failed to synchronize user after login #{ldap.name}: #{e.message}" }
      ServiceResult.failure(message: "Failed to synchronize user #{user.login}: #{e.message}")
    end
  end
end
