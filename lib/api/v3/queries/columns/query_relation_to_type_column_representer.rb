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

module API
  module V3
    module Queries
      module Columns
        class QueryRelationToTypeColumnRepresenter < QueryColumnRepresenter
          # The type this column is named after, which is the one users pick.
          link :type do
            {
              href: api_v3_paths.type(represented.type.id),
              title: represented.type.name
            }
          end

          # Every type this column counts relations to. A project runs a single member of a
          # type family and users cannot tell the members apart, so a relation to a work
          # package of any member belongs in this column.
          links :types do
            counted_types.map do |type|
              {
                href: api_v3_paths.type(type.id),
                title: type.name
              }
            end
          end

          def _type
            "QueryColumn::RelationToType"
          end

          # Includes the whole family: gaining a variant changes what the column counts
          # without touching the type it is named after.
          def json_cache_key
            [represented.name, *counted_types.map(&:cache_key_with_version)]
          end

          private

          def counted_types
            represented.type.family
          end
        end
      end
    end
  end
end
