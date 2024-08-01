# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
#
module Storages::Admin
  class GeneralInfoComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include StorageViewInformation

    alias_method :storage, :model

    def self.wrapper_key = :storage_general_info_section

    def initialize(model = nil, **options)
      auth_strategy = ::Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
                        .strategy
                        .with_user(User.current)

      @href_result = ::Storages::Peripherals::Registry
                       .resolve("#{model.short_provider_type}.queries.open_storage")
                       .call(storage: model, auth_strategy:)

      super
    end

    def open_link_was_generated
      @href_result.on_success { return true }
      @href_result.on_failure { return false }
    end

    def open_href
      @href_result.result
    end
  end
end
