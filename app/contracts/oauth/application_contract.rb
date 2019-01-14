#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'model_contract'

module Oauth
  class ApplicationContract < ::ModelContract
    def self.model
      ::Doorkeeper::Application
    end

    def validate
      validate_client_credential_user

      super
    end

    attribute :name
    attribute :redirect_uri
    attribute :confidential
    attribute :owner_id
    attribute :owner_type
    attribute :scopes
    attribute :client_credentials_user_id

    private

    def validate_client_credential_user
      return unless model.client_credentials_user_id.present?

      unless User.where(id: model.client_credentials_user_id).exists?
        errors.add :client_credentials_user_id, :invalid
      end
    end
  end
end
