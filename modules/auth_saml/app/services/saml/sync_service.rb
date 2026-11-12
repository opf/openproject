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

module Saml
  ##
  # Synchronize a configuration from ENV or legacy settings to a SAML provider record
  class SyncService
    attr_reader :name, :configuration, :contract_class

    def initialize(name, configuration, contract_class: nil)
      @name = name
      @configuration = configuration
      @contract_class = contract_class
    end

    def call
      params = ::Saml::ConfigurationMapper.new(configuration).call!
      provider = ::Saml::Provider.find_by(slug: name)

      if provider
        update(name, provider, params)
      else
        create(name, params)
      end
    end

    private

    def create(name, params)
      ::Saml::Providers::CreateService
        .new(user: User.system, contract_class:)
        .call(params)
        .on_success { |call| call.message = "Successfully saved SAML provider #{name}." }
        .on_failure { |call| call.message = "Failed to create SAML provider: #{call.message}" }
    end

    def update(name, provider, params)
      ::Saml::Providers::UpdateService
        .new(model: provider, user: User.system, contract_class:)
        .call(params)
        .on_success { |call| call.message = "Successfully updated SAML provider #{name}." }
        .on_failure { |call| call.message = "Failed to update SAML provider: #{call.message}" }
    end
  end
end
