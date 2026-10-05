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
    module Screens
      class ScreenSchemeRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty

        self_link

        property :id
        property :name
        property :description
        property :active

        property :type_items, exec_context: :decorator, getter: ->(*) { type_items }

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "ScreenScheme"
        end

        def type_items
          represented.items.map do |item|
            { _links: item_links(item) }
          end
        end

        def item_links(item)
          { type: { href: api_v3_paths.type(item.type_id) },
            createScreen: link_or_nil(:screen, item.create_screen_id),
            editScreen: link_or_nil(:screen, item.edit_screen_id),
            viewScreen: link_or_nil(:screen, item.view_screen_id),
            transitionScreen: link_or_nil(:screen, item.transition_screen_id) }.compact
        end

        def link_or_nil(path, id)
          { href: api_v3_paths.public_send(path, id) } if id
        end
      end
    end
  end
end
