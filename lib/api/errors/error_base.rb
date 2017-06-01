#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Errors
    class ErrorBase < Grape::Exceptions::Base
      attr_reader :code, :message, :details, :errors, :property

      class << self
        ##
        # Converts the given ActiveRecord errors into an Array of Error objects
        # (i.e. subclasses of ErrorBase)
        # In case the given errors contain 'critical' errors, the resulting Array will only
        # contain the critical error and no non-critical errors (avoiding information disclosure)
        # That means: The returned errors are always safe for display towards a user
        def create_errors(errors)
          if errors.has_key?(:base)
            base_errors = errors.symbols_for(:base)
            if base_errors.include?(:error_not_found)
              return [::API::Errors::NotFound.new]
            elsif base_errors.include?(:error_unauthorized)
              return [::API::Errors::Unauthorized.new]
            elsif base_errors.include?(:error_conflict)
              return [::API::Errors::Conflict.new]
            end
          end

          convert_ar_to_api_errors(errors)
        end

        ##
        # Like :create_errors, but creates a single MultipleErrors error if
        # more than one error would be returned otherwise.
        def create_and_merge_errors(errors)
          ::API::Errors::MultipleErrors.create_if_many(create_errors(errors))
        end

        ##
        # Allows defining this error class's identifier.
        # Used to read it otherwise.
        def identifier(identifier = nil)
          @identifier = identifier if identifier

          @identifier
        end

        private

        def convert_ar_to_api_errors(errors)
          api_errors = []

          errors.keys.each do |attribute|
            api_attribute_name = ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
            errors.symbols_and_messages_for(attribute).each do |symbol, full_message, _|
              if symbol == :error_readonly
                api_errors << ::API::Errors::UnwritableProperty.new(api_attribute_name)
              else
                api_errors << ::API::Errors::Validation.new(api_attribute_name, full_message)
              end
            end
          end

          api_errors
        end
      end

      def initialize(code, message)
        @code = code
        @message = message
        @errors = []
      end
    end
  end
end
