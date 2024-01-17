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

require_relative 'base_contract'

##
# Model contract for AR records that
# support change tracking
class ModelContract < BaseContract
  # Runs all the specified validations and returns +true+ if no errors were
  # added otherwise +false+.
  # Validations on the model as well as on the contract are run.
  # Since the error object of this contract is the model's error object,
  # the errors of both contract and model are both added to it.
  # After validation, the errors can thus be accessed via both means:
  #
  #   model = SomeModel.new
  #   contract = SomeModels::SomeModelContract.new(model, some_user)
  #   contract.valid? # => false
  #
  #   contract.errors == model.errors # => true
  #
  # This of course is only true if that contract validates the model and
  # if the model has an errors object.
  def valid?(context = nil)
    model.valid? if validate_model?

    contract_valid?(context, clear_errors: !validate_model?)
  end

  protected

  # This method is mostly copied from ActiveModel::Validations#valid?
  # but:
  # * does not clear errors before validation unless explicitly instructed to do so.
  #   Clearing would then be done in the #valid? method by calling model.valid?
  # * Checks for readonly attributes being changed
  def contract_valid?(context = nil, clear_errors: false)
    current_context, self.validation_context = validation_context, context # rubocop:disable Style/ParallelAssignment

    errors.clear if clear_errors

    readonly_attributes_unchanged

    run_validations!
  ensure
    self.validation_context = current_context
  end

  ##
  # Allow subclasses to disable model validation
  # during contract validation.
  #
  # This is necessary during, e.g., deletion contract validations
  # to ensure invalid models can be deleted when allowed.
  def validate_model?
    true
  end

  private

  def readonly_attributes_unchanged
    unauthenticated_changed.each do |attribute|
      outside_attribute = ancestor_attribute_aliases[attribute] || attribute

      errors.add outside_attribute, :error_readonly
    end
  end

  def unauthenticated_changed
    changed_by_user - writable_attributes
  end

  def changed_by_user
    return model.changed_by_user if model.respond_to?(:changed_by_user)
    return model.changed_with_custom_fields if model.respond_to?(:changed_with_custom_fields)

    model.changed
  end
end
