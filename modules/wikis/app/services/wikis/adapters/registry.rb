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

require "dry/core/container"

module Wikis
  module Adapters
    class Registry
      extend Dry::Core::Container::Mixin

      class Error < StandardError
      end

      class MissingContract < Error
      end

      class OperationNotSupported < Error
      end

      class UnknownProvider < Error
      end

      def self.known_providers
        keys.map { it.split(".").first }.uniq
      end

      class Resolver < Dry::Core::Container::Resolver
        def call(container, key)
          Rails.logger.tagged("Wikis::Adapters::Registry") do
            Rails.logger.info "Resolving #{key}"
            super
          end
        rescue Dry::Core::Container::KeyError => e
          error = registry_error_for(key)

          Rails.logger.tagged("Wikis::Adapters::Registry") { Rails.logger.error (error || e).message }
          raise if error.nil?

          raise error
        end

        private

        def registry_error_for(key)
          case key.split(".")
          in [provider, *] if Registry.known_providers.exclude?(provider)
            UnknownProvider.new(provider)
          in [provider, "contracts", model]
            MissingContract.new("No #{model} contract defined for provider: #{provider.camelize}")
          in [provider, "commands" | "queries" => type, operation]
            OperationNotSupported.new(
              "#{type.singularize.capitalize} #{operation} not supported by provider: #{provider.camelize}"
            )
          end
        end
      end

      config.resolver = Resolver.new

      import Providers::Internal::Registry
      import Providers::XWiki::Registry
    end
  end
end
