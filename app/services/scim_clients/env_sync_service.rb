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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ScimClients
  class EnvSyncService
    attr_reader :config

    def initialize(env_config)
      @config = env_config.deep_symbolize_keys
    end

    def call
      existing_client = find_existing_client
      ActiveRecord::Base.transaction do
        if existing_client
          update!(existing_client)
        else
          create!
        end
      end
    end

    def create!
      CreateService.new(user:, contract_class: EnvironmentCreateContract).call(**attributes)
    end

    def update!(client)
      UpdateService.new(user:, model: client, contract_class: EnvironmentUpdateContract).call(**attributes)
    end

    private

    def find_existing_client
      ScimClient.find_by(name: config.fetch(:name))
    end

    def user = User.system

    def attributes
      {
        name: config.fetch(:name),
        jwt_sub: config.fetch(:jwt_sub),
        auth_provider_id: AuthProvider.find_by!(slug: config.fetch(:auth_provider_slug)).id,
        authentication_method: :sso
      }
    end

    def result!(service_result)
      raise service_result.message if service_result.failure?

      service_result.result
    end
  end
end
