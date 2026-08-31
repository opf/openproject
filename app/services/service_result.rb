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

##
# Represents the result of a call to a service.
#
# @example
#   result = Projects::UpdateService
#     .new(user: current_user, model: @project)
#     .call(permitted_params.project)
#   result.success? # => true if the service call was successful.
#   result.result # => #<Project id: 1011>
#   result.errors # => #<ActiveModel::Errors []>
#
class ServiceResult
  SUCCESS = true
  FAILURE = false
  private_constant :SUCCESS, :FAILURE

  # @return [Boolean] whether the service call was successful.
  attr_accessor :success

  ##
  # Returns the result of the service call. In typical usage this will be a
  # model, i.e. an {ActiveRecord::Base} descendant.
  #
  # @return [Object, nil] the service call result object. This can also be nil.
  attr_accessor :result

  # @return [ActiveModel::Errors] errors resulting from the service call.
  attr_accessor :errors

  # @return [Array<ServiceResult>] all dependent ServiceResults - by virtue of
  #   the service calling other services.
  attr_accessor :dependent_results

  attr_writer :message,
              :state

  # @!macro factory_params
  #   @param errors [ActiveModel::Errors, nil] errors resulting from the service call.
  #   @param message [String, nil] an error message associated with the service call.
  #   @param message_type [#to_sym, nil] the type of error message when displayed as a Controller flash message.
  #   @param state [Shared::ServiceState, nil] the Service State object.
  #   @param dependent_results [Array<ServiceResult>] any dependent ServiceResults.
  #   @param result [Object, nil] the result of the service call.
  #
  # @!macro factory_method
  #   @overload $0(errors: nil, message: nil, message_type: nil, state: nil, dependent_results: [], result: nil)
  #     @macro factory_params

  ##
  # Creates a ServiceResult for a successful service call.
  #
  # @macro factory_method
  # @return [ServiceResult] a new, successful instance of ServiceResult.
  def self.success(**)
    new(**, success: SUCCESS)
  end

  ##
  # Creates a ServiceResult for a failed service call.
  #
  # @macro factory_method
  # @return [ServiceResult] a new, failed instance of ServiceResult.
  def self.failure(**)
    new(**, success: FAILURE)
  end

  ##
  # @note
  #   Prefer using {.success} or {.failure} factory methods to calling
  #   `ServiceResult.new(success: true)` or `ServiceResult.new(success: false)`.
  #
  # Creates a ServiceResult for a service call.
  #
  # @param [Boolean] success whether the service call was successful.
  # @macro factory_params
  def initialize(success: FAILURE,
                 errors: nil,
                 message: nil,
                 message_type: nil,
                 state: nil,
                 dependent_results: [],
                 result: nil)
    self.success = success
    self.result = result
    self.state = state

    initialize_errors(errors, result)
    @message = message
    @message_type = message_type

    self.dependent_results = dependent_results
  end

  # @see failure?
  # @return [Boolean] whether the service call succeeded.
  alias success? success

  # @see success?
  # @return [Boolean] whether the service call failed.
  def failure?
    !success?
  end

  ##
  # Merges another ServiceResult into this instance, optionally allowing its
  # {#success} to be ignored.
  #
  # @param other [ServiceResult] the other ServiceResult.
  # @param without_success [Boolean] whether to ignore the {#success} of the
  #   other ServiceResult.
  # @return [void]
  def merge!(other, without_success: false)
    merge_success!(other) unless without_success
    merge_errors!(other)
    merge_dependent!(other)

    self
  end

  ##
  # Prints messages to the Controller's flash.
  #
  # @param flash [ActionDispatch::Flash::FlashHash]
  # @return [void]
  def apply_flash_message!(flash)
    if message
      flash[message_type] = message
    end
  end

  ##
  # Returns all {#result}s, including from dependent ServiceResults.
  #
  # @return [Array<Object, nil>] all results.
  def all_results
    dependent_results.map(&:result).tap do |results|
      results.unshift result unless result.nil?
    end
  end

  ##
  # Returns all {#errors}, including from dependent ServiceResults.
  #
  # @return [Array<ActiveModel::Errors>] all errors.
  def all_errors
    [errors] + dependent_results.map(&:errors)
  end

  ##
  # Tests whether the returned errors, including from dependent ServiceResults,
  # include the error key.
  #
  # @param attribute [:base, Symbol] the attribute.
  # @param error_key [Symbol] the type of the error.
  # @return [Boolean] whether the returned errors include the error key.
  def includes_error?(attribute, error_key)
    all_errors.any? do |error|
      error.symbols_for(attribute).include?(error_key)
    end
  end

  ##
  # Returns dependent ServiceResults with errors, and optionally self, if self
  # has errors.
  #
  # @param include_self [Boolean] whether to include self, if self has errors.
  # @return [Array<ServiceResult>] all ServiceResults with errors.
  def results_with_errors(include_self: true)
    results =
      if include_self
        [self] + dependent_results
      else
        dependent_results
      end

    results.reject { |call| call.errors.empty? }
  end

  # @return [Array<ServiceResult>] self and dependent ServiceResults.
  def self_and_dependent
    [self] + dependent_results
  end

  ##
  # Adds a dependent ServiceResult.
  #
  # @param [ServiceResult] dependent the dependent ServiceResult to add.
  def add_dependent!(dependent)
    merge_success!(dependent)

    inner_results = dependent.dependent_results
    dependent.dependent_results = []

    dependent_results << dependent
    self.dependent_results += inner_results
  end

  ##
  # Executes block argument if the service call succeeded.
  #
  # @yield block to be called on success.
  # @return [self]
  def on_success(&)
    tap(&) if success?
    self
  end

  ##
  # Executes block argument if the service call failed.
  #
  # @yield block to be called on failure.
  # @return [self]
  def on_failure(&)
    tap(&) if failure?
    self
  end

  ##
  # Chains a subsequent service call if this result is successful, short-circuiting on failure.
  # Useful for composing several potentially-failing operations, returning the last successful
  # ServiceResult or the first failing one.
  #
  # @yield block to be called on success.
  # @yieldparam result [Object, nil] the result of the service call.
  # @yieldreturn [ServiceResult] the next ServiceResult in the chain.
  # @return [ServiceResult] the block's ServiceResult on success, or self on failure.
  def bind
    success? ? yield(result) : self
  end

  ##
  # Iterates exactly once, passing the result to the block, if the service call
  # succeeded.
  #
  # @see Enumerable#each
  # @yield block to be called on success.
  # @yieldparam result [Object, nil] the result of the service call.
  # @return [self]
  def each
    yield result if success?
    self
  end

  ##
  # If the service call succeeded, returns a copy of the ServiceResult whose
  # whose {#result} is the return value from the block. Iterates exactly once
  # if the service call succeeded.
  #
  # @yield block to be called on success.
  # @yieldparam result [Object, nil] the result of the service call.
  # @return [ServiceResult] a new ServiceResult with the result.
  def map
    return self if failure?

    dup.tap do |new_result|
      new_result.result = yield result
    end
  end

  # @return [Array<Object, nil>] the {#result} wrapped in an Array if the
  #   service call succeeded, or an empty Array if the service call failed.
  def to_a
    if success?
      [result]
    else
      []
    end
  end

  ##
  # Allows ServiceResult to be used with pattern matching.
  #
  # @param [Array<:success, :failure, :result, :error>] keys the keys to match
  #   on.
  # @return [Hash{Symbol=>Object}] the match result.
  def deconstruct_keys(keys)
    if keys
      value = {}
      keys.each do |key|
        case key
        when :success then value[key] = success?
        when :failure then value[key] = failure?
        when :result then value[key] = result
        when :errors then value[key] = errors
        end
      end

      value
    else
      { success: success?, failure: failure?, result:, errors: }
    end
  end

  # @return [String] error message associated with the service call.
  def message
    if @message
      @message
    elsif failure?
      if errors.is_a?(ActiveModel::Errors)
        errors.full_messages.join(" ")
      elsif errors.respond_to?(:message)
        errors.message
      end
    end
  end

  # @return [Shared::ServiceState] the Service State object.
  def state
    @state ||= ::Shared::ServiceState.build
  end

  ##
  # @api private
  # @note
  #   Required as we create an errors object bound to this ServiceResult.
  #   Calling `errors#full_messages` will call {.human_attribute_name} here.
  #
  # @see ApplicationRecord.human_attribute_name
  # @return [String] the attribute name in a more human format
  def self.human_attribute_name(*)
    ApplicationRecord.human_attribute_name(*)
  end

  def message_type
    if @message_type
      @message_type.to_sym
    elsif success?
      :notice
    else
      :error
    end
  end

  private

  def initialize_errors(errors, provided_result)
    self.errors = errors || new_errors_with_result(provided_result)
  end

  def new_errors_with_result(provided_result)
    base = provided_result.respond_to?(:errors) ? provided_result : self
    ActiveModel::Errors.new(base).tap do |errors|
      errors.merge!(provided_result) if base != self
    end
  end

  def merge_success!(other)
    self.success &&= other.success
  end

  def merge_errors!(other)
    errors.merge! other.errors
  end

  def merge_dependent!(other)
    self.dependent_results += other.dependent_results
  end
end
