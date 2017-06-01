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
  module V3
    module Queries
      module SortBys
        class SortByDecorator
          def initialize(column, direction)
            if !['asc', 'desc'].include?(direction)
              raise ArgumentError, "Invalid direction. Only 'asc' and 'desc' are supported."
            end

            if column.nil?
              raise ArgumentError, "Column needs to be set"
            end

            self.direction = direction
            self.column = column
          end

          def id
            "#{converted_name}-#{direction_name}"
          end

          def name
            I18n.t('query.attribute_and_direction',
                   attribute: column_caption,
                   direction: direction_l10n)
          end

          def converted_name
            convert_attribute(column_name)
          end

          def direction_name
            direction
          end

          def direction_uri
            "urn:openproject-org:api:v3:queries:directions:#{direction}"
          end

          def direction_l10n
            I18n.t(direction == 'desc' ? :label_descending : :label_ascending)
          end

          def column_name
            column.name
          end

          def column_caption
            column.caption
          end

          private

          def convert_attribute(attribute)
            ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
          end

          attr_accessor :direction, :column
        end
      end
    end
  end
end
