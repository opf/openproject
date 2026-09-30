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

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module ProviderResults
          Capabilities = Data.define(:app_enabled, :group_folder_enabled, :app_version, :group_folder_version) do
            private_class_method :new

            def self.build(app_enabled:, group_folder_enabled:, app_version:,
                           group_folder_version:, contract: CapabilitiesContract.new)
              contract.call(app_enabled:, group_folder_enabled:, app_version:, group_folder_version:)
                      .to_monad.fmap { new(**it.to_h) }
            end

            def self.empty
              new(app_enabled: false, group_folder_enabled: false, app_version: nil, group_folder_version: nil)
            end

            alias_method :app_enabled?, :app_enabled
            alias_method :group_folder_enabled?, :group_folder_enabled

            def app_disabled? = !app_enabled?
            def group_folder_disabled? = !group_folder_enabled?

            def with(...)
              args = to_h.merge(...)
              self.class.build(**args).either(-> { it }, -> { raise ArgumentError, it.errors })
            end
          end
        end
      end
    end
  end
end
