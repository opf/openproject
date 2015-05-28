#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Errors
    class Validation < ErrorBase
      identifier 'urn:openproject-org:api:v3:errors:PropertyConstraintViolation'

      def self.create(errors)
        merge_error_properties(errors)

        errors.keys.each_with_object({}) do |attribute, hash|
          messages = errors[attribute].each_with_object([]) do |message, message_list|
            # Let's assume that standard validation errors never end with a
            # punctuation mark. Then it should be fair enough to assume that we
            # don't need to prepend the error key if the error ends with a
            # punctuation mark. Let's hope that this is true for the languages
            # we'll support in OpenProject.
            if message =~ /(\.|\?|\!)\z/
              message_list << message
            else
              message_list << errors.full_message(attribute, message) + '.'
            end
          end

          hash[attribute.to_s.camelize(:lower)] = ::API::Errors::Validation.new(messages)
        end
      end

      # Merges property error messages (e.g. for status and status_id)
      def self.merge_error_properties(errors)
        properties = errors.keys

        properties.each do |p|
          match = /(?<property>\w+)_id/.match(p)

          if match
            key = match[:property].to_sym
            error = Array(errors[key]) + errors[p]

            errors.set(key, error)
            errors.delete(p)
          end
        end
      end

      def initialize(messages)
        messages = Array(messages)

        if messages.length == 1
          message = messages[0]
        else
          message = I18n.t('api_v3.errors.multiple_errors')
        end

        super 422, message

        messages.each { |m| @errors << Validation.new(m) } if messages.length > 1
      end
    end
  end
end
