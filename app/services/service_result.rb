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

class ServiceResult
  attr_accessor :success,
                :result,
                :errors,
                :message_type,
                :context,
                :dependent_results

  def initialize(success: false,
                 errors: nil,
                 message: nil,
                 message_type: nil,
                 context: {},
                 dependent_results: [],
                 result: nil)
    self.success = success
    self.result = result
    self.context = context

    initialize_errors(errors)
    @message = message

    self.dependent_results = dependent_results
  end

  alias success? :success

  def failure?
    !success?
  end

  def merge!(other)
    merge_success!(other)
    merge_dependent!(other)
  end

  ##
  # Print messages to flash
  def apply_flash_message!(flash)
    type = get_message_type

    if message && type
      flash[type] = message
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
  # Collect all present errors for the given result
  # and dependent results.
  #
  # Returns a map of the service reuslt to the error object
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

  def on_success
    yield(self) if success?
  end

  def on_failure
    yield(self) if failure?
  end

  def message
    if @message
      @message
    elsif failure? && errors.is_a?(ActiveModel::Errors)
      errors.full_messages.join(" ")
    end
  end

  private

  def initialize_errors(errors)
    self.errors =
      if errors
        errors
      elsif result.respond_to?(:errors)
        result.errors
      else
        ActiveModel::Errors.new(self)
      end
  end


  def get_message_type
    if message_type.present?
      message_type.to_sym
    elsif success?
      :notice
    else
      :error
    end
  end

  def merge_success!(other)
    self.success &&= other.success
  end

  def merge_dependent!(other)
    self.dependent_results += other.dependent_results
  end
end
