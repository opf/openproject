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

class ServiceResult
  SUCCESS = true
  FAILURE = false

  attr_accessor :success,
                :result,
                :errors,
                :dependent_results

  attr_writer :state

  # Creates a successful ServiceResult.
  def self.success(errors: nil,
                   message: nil,
                   message_type: nil,
                   state: nil,
                   dependent_results: [],
                   result: nil)
    new(success: SUCCESS,
        errors:,
        message:,
        message_type:,
        state:,
        dependent_results:,
        result:)
  end

  # Creates a failed ServiceResult.
  def self.failure(errors: nil,
                   message: nil,
                   message_type: nil,
                   state: nil,
                   dependent_results: [],
                   result: nil)
    new(success: FAILURE,
        errors:,
        message:,
        message_type:,
        state:,
        dependent_results:,
        result:)
  end

  def initialize(success: false,
                 errors: nil,
                 message: nil,
                 message_type: nil,
                 state: nil,
                 dependent_results: [],
                 result: nil)
    self.success = success
    self.result = result
    self.state = state

    initialize_errors(errors)
    @message = message
    @message_type = message_type

    self.dependent_results = dependent_results
  end

  alias success? :success

  def failure?
    !success?
  end

  ##
  # Merge another service result into this instance
  # allowing optionally to skip updating its service
  def merge!(other, without_success: false)
    merge_success!(other) unless without_success
    merge_errors!(other)
    merge_dependent!(other)
  end

  ##
  # Print messages to flash
  def apply_flash_message!(flash)
    if message
      flash[message_type] = message
    end
  end

  def all_results
    dependent_results.map(&:result).tap do |results|
      results.unshift result unless result.nil?
    end
  end

  def all_errors
    [errors] + dependent_results.map(&:errors)
  end

  ##
  # Test whether the returned errors respond
  # to the search key
  def includes_error?(attribute, error_key)
    all_errors.any? do |error|
      error.symbols_for(attribute).include?(error_key)
    end
  end

  ##
  # Collect all present errors for the given result
  # and dependent results.
  #
  # Returns a map of the service result to the error object
  def results_with_errors(include_self: true)
    results =
      if include_self
        [self] + dependent_results
      else
        dependent_results
      end

    results.reject { |call| call.errors.empty? }
  end

  def self_and_dependent
    [self] + dependent_results
  end

  def add_dependent!(dependent)
    merge_success!(dependent)

    inner_results = dependent.dependent_results
    dependent.dependent_results = []

    dependent_results << dependent
    self.dependent_results += inner_results
  end

  def on_success(&)
    tap(&) if success?
    self
  end

  def on_failure(&)
    tap(&) if failure?
    self
  end

  def each
    yield result if success?
    self
  end

  def map
    return self if failure?

    dup.tap do |new_result|
      new_result.result = yield result
    end
  end

  def to_a
    if success?
      [result]
    else
      []
    end
  end

  def message
    if @message
      @message
    elsif failure? && errors.is_a?(ActiveModel::Errors)
      errors.full_messages.join(" ")
    end
  end

  def state
    @state ||= ::Shared::ServiceState.build
  end

  private

  def initialize_errors(errors)
    self.errors = errors || new_errors_with_result
  end

  def new_errors_with_result
    ActiveModel::Errors.new(self).tap do |errors|
      errors.merge!(result) if result.try(:errors).present?
    end
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
