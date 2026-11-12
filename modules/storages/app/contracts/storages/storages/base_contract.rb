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

require "net/http"
require "uri"

module Storages
  module Storages
    class BaseContract < ::BaseContract
      include Concerns::ManageStoragesGuarded

      class Factory
        def initialize(contract_class, provider_contract)
          @contract_class = contract_class
          @provider_contract = provider_contract
        end

        def new(*, **)
          @contract_class.new(*, provider_contract: @provider_contract, **)
        end

        delegate :<=, to: :@contract_class
      end

      class << self
        def with_provider_contract(provider_contract)
          Factory.new(self, provider_contract)
        end
      end

      attribute :provider_type
      validates :provider_type, inclusion: { in: -> { Storage.provider_types.values.map(&:to_s) } }, allow_nil: false

      attribute :provider_fields

      validate :provider_type_strategy,
               unless: -> { errors.include?(:provider_type) || @options.delete(:skip_provider_type_strategy) }

      def initialize(*, provider_contract: nil, **)
        super(*, **)

        @provider_contract = provider_contract
      end

      private

      def provider_type_strategy
        contract = provider_contract.new(model, @user, options: @options)

        # Append the attributes defined in the internal contract
        # to the list of writable attributes.
        # Otherwise, we get :readonly validation errors.
        contract.writable_attributes.append(*writable_attributes)

        validate_and_merge_errors(contract)
      end

      def provider_contract
        @provider_contract || default_provider_contract
      end

      def default_provider_contract
        ::Storages::Adapters::Registry.resolve("#{model}.contracts.storage")
      end
    end
  end
end
