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

    # @param attribute [Symbol] attribute to which the error will be tied to
    # @param storage_error [Storages::StorageError] an StorageError instance
    # @param options [Hash{Symbol => Object}] optional extra parameters for the message generation
    # @return ServiceResult
    def add_error(attribute, storage_error, options: {})
      case storage_error.code
      when :error, :unauthorized
        @result.errors.add(:base, storage_error.code, **options)
      else
        @result.errors.add(attribute, storage_error.code, **options)
      end

      @result
    end
  end
end
