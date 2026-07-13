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

require "dry/core/container"

module Storages
  module Adapters
    class Registry
      extend Dry::Core::Container::Mixin

      # Extracts the known_providers from the registered keys
      # @return [Array<String>]
      def self.known_providers
        keys.map { it.split(".").first }.uniq
      end

      class Resolver < Dry::Core::Container::Resolver
        include TaggedLogging

        def call(container, key)
          with_tagged_logger("Storages::Adapters::Registry") do
            info "Resolving #{key}"
            super
          end
        rescue Dry::Core::Container::KeyError
          error = Errors.registry_error_for(key)

          with_tagged_logger("Storages::Adapters::Registry") { error error.message }
          raise error
        end
      end

      config.resolver = Resolver.new

      # Need to make this dynamic to ease new providers to be registered
      import Providers::Nextcloud::NextcloudRegistry
      import Providers::OneDrive::OneDriveRegistry
      import Providers::Sharepoint::SharepointRegistry
    end
  end
end
