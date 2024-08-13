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

module Contracted
  extend ActiveSupport::Concern

  included do
    attr_reader :contract_class
    attr_accessor :contract_options

    def contract_class=(cls)
      unless cls <= ::BaseContract
        raise ArgumentError, "#{cls.name} is not an instance of BaseContract."
      end

      @contract_class = cls
    end

    private

    def instantiate_contract(object, user, options: {})
      contract_class.new(object, user, options:)
    end

    def validate_and_save(object, user, options: {})
      validate_and_yield(object, user, options:) do
        object.save
      end
    end

    ##
    # Call the given block and assume object is erroneous if
    # it does not return truthy
    def validate_and_yield(object, user, options: {})
      contract = instantiate_contract(object, user, options:)

      if contract.validate
        success = !!yield
        [success, object&.errors]
      else
        [false, contract.errors]
      end
    end

    def validate(object, user, options: {})
      validate_and_yield(object, user, options:) do
        # No object validation is necessary at this point
        # as object.valid? is already called in the contract
        true
      end
    end
  end
end
