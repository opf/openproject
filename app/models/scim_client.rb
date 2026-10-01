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

class ScimClient < ApplicationRecord
  belongs_to :auth_provider

  has_one :oauth_application, class_name: "::Doorkeeper::Application", as: :integration, dependent: :destroy

  has_one :service_account_association, as: :service, dependent: :destroy
  has_one :service_account, through: :service_account_association

  enum :authentication_method, {
    sso: 0,
    oauth2_client: 1,
    oauth2_token: 2
  }, scopes: false, prefix: true

  def configured_from_env?
    Setting.scim_clients.any? { |c| c["name"] == name_was }
  end

  def access_tokens
    return Doorkeeper::AccessToken.none unless authentication_method_oauth2_token?

    oauth_application.access_tokens
  end

  def jwt_sub
    auth_provider_link&.external_id
  end

  # This method is part of a nasty workaround for creating and updating SCIM clients:
  # To be able to validate the jwt_sub, the SetAttributesService must be able to effectively set the jwt_sub,
  # before it's validated by a contract. Afterwards the UpdateService must be able to persist the change. Since
  # user_auth_provider_links is a has_many association, there is no built-in memoization for values. So to make sure the
  # SetAttributesService, the Contract and the UpdateService all look at the same jwt_sub, we memoize the auth_provider_link here
  def auth_provider_link
    @auth_provider_link ||= service_account&.user_auth_provider_links&.first
  end
end
