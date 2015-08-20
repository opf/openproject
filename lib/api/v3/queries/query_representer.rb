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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Queries
      class QueryRepresenter < ::API::Decorators::Single

        self_link

        linked_property :user
        linked_property :project

        property :id
        property :name
        property :filters,
                 exec_context: :decorator,
                 getter: -> (*) {
                   represented.filters.map { |filter|
                     attribute = convert_attribute filter.field
                     {
                       attribute => { operator: filter.operator, values: filter.values }
                     }
                   }
                 }
        property :is_public, getter: -> (*) { is_public }
        property :column_names,
                 exec_context: :decorator,
                 getter: -> (*) {
                   return nil unless represented.column_names
                   represented.column_names.map { |name|  convert_attribute name }
                 }
        property :sort_criteria,
                 exec_context: :decorator,
                 getter: -> (*) {
                   return nil unless represented.sort_criteria
                   represented.sort_criteria.map { |attribute, order|
                     [convert_attribute(attribute), order]
                   }
                 }
        property :group_by,
                 exec_context: :decorator,
                 getter: -> (*) {
                   represented.grouped? ? convert_attribute(represented.group_by) : nil
                 },
                 render_nil: true
        property :display_sums, getter: -> (*) { display_sums }
        property :is_starred, getter: -> (*) { starred }

        private

        def convert_attribute(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
        end

        def _type
          'Query'
        end
      end
    end
  end
end
