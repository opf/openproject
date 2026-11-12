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

##
# A contract that allows to compose itself from other contracts like:
#
#     class MyContract < ComposedContract
#       include_contract MyOtherContractA
#       include_contract MyOtherContractB
#     end
#
# This allows to run the smaller contracts separately, but also to have one contract
# that validates the model as a whole. The composed contract will make sure that all attributes
# defined as writable in one contract are also considered writable in other contracts.
#
# It's not possible to add validations to the composed contract directly. If you need additional validations,
# extract them into a separate contract that you include in the composed contract.
class ComposedContract
  class << self
    def included_contract_classes
      @included_contract_classes ||= []
    end

    def include_contract(contract_class)
      included_contract_classes << contract_class
    end
  end

  attr_reader :errors, :model, :writable_attributes

  def initialize(model, user, options: {})
    @model = model
    @user = user
    @options = options

    @errors = ActiveModel::Errors.new(model)
    @writable_attributes = []
  end

  def validate
    errors.clear
    included_contracts.each do |subcontract|
      subcontract.validate
      errors.merge!(subcontract.errors)
    end

    errors.empty?
  end

  def valid?
    validate
  end

  private

  def included_contracts
    @included_contracts ||= begin
      contracts = self.class.included_contract_classes.map { |klass| klass.new(model, @user, options: @options) }
      all_writable_attributes = (writable_attributes + contracts.flat_map(&:writable_attributes)).uniq
      contracts.each do |subcontract|
        subcontract.writable_attributes.append(*all_writable_attributes)
      end

      contracts
    end
  end
end
