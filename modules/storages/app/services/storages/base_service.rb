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
  class BaseService
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include Dry::Monads[:result]

    include TaggedLogging

    class << self
      def i18n_key=(value)
        @yaml_key = value
      end

      def i18n_key = @yaml_key || class_name

      def i18n_scope = "services"

      def model_name = ActiveModel::Name.new(self, Storages, i18n_key)
    end

    def initialize
      @result = ServiceResult.success(errors: ActiveModel::Errors.new(self))
    end

    def read_attribute_for_validation(attr) = attr

    private

    def add_validation_error(validation_error, options: {})
      log_validation_error(validation_error, options:)

      @result.errors.add(:base, :invalid, **validation_error.to_h)
      @result.success = false
      @result
    end

    # @param attribute [Symbol] attribute to which the error will be tied to
    # @param error [Storages::Adapters::Results::Error] An adapter error result
    # @param options [Hash{Symbol => Object}] optional extra parameters for the message generation
    # @return ServiceResult
    def add_error(attribute, error, options: {})
      log_adapter_error(error, options)

      if %i[error unauthorized not_found].include? error.code
        @result.errors.add(:base, error.code, **options)
      else
        @result.errors.add(attribute, error.code, **options)
      end

      @result.success = false
      @result
    end
  end
end
