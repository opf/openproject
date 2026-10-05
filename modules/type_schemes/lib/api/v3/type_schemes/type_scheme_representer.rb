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
    module TypeSchemes
      class TypeSchemeRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty

        self_link

        property :id
        property :name
        property :description
        property :active
        property :is_default

        property :type_items,
                 exec_context: :decorator,
                 getter: ->(*) { type_items }

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "TypeScheme"
        end

        def type_items
          represented.items.sort_by(&:position).map do |item|
            {
              _links: { type: { href: api_v3_paths.type(item.type_id) } },
              position: item.position,
              default: item.is_default,
              color: color_hash(item.color)
            }
          end
        end

        def color_hash(color)
          return if color.nil?

          { id: color.id, name: color.name, hexcode: color.hexcode }
        end
      end
    end
  end
end
