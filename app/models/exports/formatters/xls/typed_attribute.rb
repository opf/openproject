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

module Exports
  module Formatters
    module XLS
      class TypedAttribute < Default
        COLUMN_TYPES = %i[date datetime integer float decimal boolean].freeze

        class << self
          def model_class
            raise SubclassResponsibilityError
          end

          def apply?(attribute, export_format)
            export_format == :xls && column_type(attribute).present?
          end

          def column_type(attribute)
            type = model_class.columns_hash[attribute.to_s]&.type
            type if type.in?(COLUMN_TYPES)
          end
        end

        def format_value(value, _options = {})
          return nil if value.nil?

          case column_type
          when :date then value.to_date
          when :datetime then in_user_zone(value)
          when :integer then value.to_i
          when :boolean then value
          else value.to_f
          end
        end

        def format_options
          case column_type
          when :date then { number_format: DateFormat.date }
          when :datetime then { number_format: DateFormat.datetime }
          when :integer then { number_format: integer_format }
          when :boolean then {}
          else { number_format: }
          end
        end

        private

        def column_type
          @column_type ||= self.class.column_type(attribute)
        end
      end
    end
  end
end
