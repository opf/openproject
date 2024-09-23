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

module Storages
  module Errors
    class BaseError < StandardError; end

    class ResolverStandardError < BaseError; end

    class PollingRequired < BaseError; end

    class ConfigurationError < BaseError; end

    class MissingContract < ResolverStandardError; end

    class OperationNotSupported < ResolverStandardError; end

    class MissingModel < ResolverStandardError; end

    class SubclassResponsibility < BaseError
      def message
        "A subclass needs to implement its own version of this method."
      end
    end

    class IntegrationJobError < BaseError; end

    def self.registry_error_for(key)
      case key.split(".")
      in [storage, "contracts", model]
        MissingContract.new("No #{model} contract defined for provider: #{storage.camelize}")
      in [storage, "commands" | "queries" => type, operation]
        OperationNotSupported.new(
          "#{type.singularize.capitalize} #{operation} not supported by provider: #{storage.camelize}"
        )
      in [storage, "models", object]
        MissingModel.new("Model #{object} not registered for provider: #{storage.camelize}")
      else
        ResolverStandardError.new("Cannot resolve key #{key}.")
      end
    end
  end
end
