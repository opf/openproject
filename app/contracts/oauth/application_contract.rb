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

module OAuth
  class ApplicationContract < ::ModelContract
    def self.model
      ::Doorkeeper::Application
    end

    validate :validate_client_credential_user
    validate :validate_integration

    attribute :name
    attribute :redirect_uri
    attribute :confidential
    attribute :owner_id
    attribute :owner_type
    attribute :scopes
    attribute :client_credentials_user_id
    attribute :integration_id
    attribute :integration_type

    private

    def validate_integration
      if (model.integration_id.nil? && model.integration_type.present?) ||
         (model.integration_id.present? && model.integration_type.nil?)
        errors.add :integration, :invalid
      end
    end

    def validate_client_credential_user
      return if model.client_credentials_user_id.blank?

      unless User.exists?(id: model.client_credentials_user_id)
        errors.add :client_credentials_user_id, :invalid
      end
    end
  end
end
