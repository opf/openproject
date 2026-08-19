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
    module CustomFields
      module Hierarchy
        class HierarchyItemRepresenter < ::API::Decorators::Single
          def _type
            "HierarchyItem"
          end

          self_link path: :custom_field_item,
                    title_getter: ->(*) { represented.title }

          property :id

          property :label, render_nil: true

          property :short, render_nil: true

          property :weight, render_nil: true

          property :formatted_weight, render_nil: true

          property :depth,
                   render_nil: true,
                   exec_context: :decorator,
                   getter: ->(*) { represented.depth < 0 ? nil : represented.depth }

          link :parent do
            next if represented.root?

            parent = represented.parent

            {
              href: api_v3_paths.custom_field_item(parent.id),
              title: parent.label
            }
          end

          links :children do
            represented.children.map do |child|
              {
                href: api_v3_paths.custom_field_item(child.id),
                title: child.label
              }
            end
          end

          link :branch do
            { href: api_v3_paths.custom_field_item_branch(represented.id) }
          end
        end
      end
    end
  end
end
