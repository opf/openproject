#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Contracted
  extend ActiveSupport::Concern

  included do
    attr_reader :contract_class
    attr_accessor :contract_options

    def contract_class=(cls)
      unless cls <= ::ModelContract
        raise ArgumentError "#{cls.name} is not an instance of ModelContract."
      end

      @contract_class = cls
    end

    def changed_by_system(attributes = nil)
      @changed_by_system ||= []

      if attributes
        @changed_by_system += Array(attributes)
      end

      @changed_by_system
    end

    def change_by_system
      prior_changes = non_no_op_changes

      ret = yield

      changed_by_system(changed_compared_to(prior_changes))

      ret
    end

    private

    def instantiate_contract(object, user, options: {})
      contract_class.new(object, user, options: { changed_by_system: changed_by_system }.merge(options))
    end

    def validate_and_save(object, user, options: {})
      validate_and_yield(object, user, options: options) do
        object.save
      end
    end

    ##
    # Call the given block and assume object is erroneous if
    # it does not return truthy
    def validate_and_yield(object, user, options: {})
      contract = instantiate_contract(object, user, options: options)

      if !contract.validate
        [false, contract.errors]
      elsif !yield
        [false, object.errors]
      else
        [true, object.errors]
      end
    end

    def validate(object, user, options: {})
      validate_and_yield(object, user, options: options) do
        # No object validation is necessary at this point
        # as object.valid? is already called in the contract
        true
      end
    end

    def non_no_op_changes
      model.changes.reject { |_, (old, new)| old == 0 && new.nil? }
    end

    def changed_compared_to(prior_changes)
      model.changed.select { |c| !prior_changes[c] || prior_changes[c].last != model.changes[c].last }
    end
  end
end
