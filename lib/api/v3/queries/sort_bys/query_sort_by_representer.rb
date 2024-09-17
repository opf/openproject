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
      module SortBys
        class QuerySortByRepresenter < ::API::Decorators::Single
          include API::Utilities::RepresenterToJsonCache

          self_link id_attribute: ->(*) { self_link_params },
                    title_getter: ->(*) { represented.name }

          def initialize(model, *_)
            super(model, current_user: nil, embed_links: true)
          end

          link :column do
            {
              href: api_v3_paths.query_column(represented.converted_name),
              title: represented.column_caption
            }
          end

          link :direction do
            {
              href: represented.direction_uri,
              title: represented.direction_l10n
            }
          end

          property :id

          property :name

          def self_link_params
            [represented.converted_name, represented.direction_name]
          end

          def _type
            "QuerySortBy"
          end

          def json_cache_key
            [represented.column_caption, represented.direction_name]
          end
        end
      end
    end
  end
end
