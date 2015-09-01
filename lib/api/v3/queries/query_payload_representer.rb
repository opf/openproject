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
      class QueryPayloadRepresenter < ::API::Decorators::Single
        def initialize(query)
          super(query, current_user: nil)
        end

        property :name
        property :filters,
                 exec_context: :decorator,
                 getter: -> (*) { serializer.format_filters },
                 setter: -> (value, *) { serializer.parse_filters(value) }
        property :column_names,
                 exec_context: :decorator,
                 getter: -> (*) { serializer.format_columns },
                 setter: -> (value, *) { serializer.parse_columns(value) }
        property :sort_criteria,
                 exec_context: :decorator,
                 getter: -> (*) { serializer.format_sorting },
                 setter: -> (value, *) { serializer.parse_sorting(value) }
        property :group_by,
                 exec_context: :decorator,
                 getter: -> (*) { serializer.format_group_by },
                 setter: -> (value, *) { serializer.parse_group_by(value) },
                 render_nil: true
        property :display_sums

        private

        def serializer
          @serializer ||= ::API::V3::Queries::QuerySerializationHelper.new(represented)
        end
      end
    end
  end
end
