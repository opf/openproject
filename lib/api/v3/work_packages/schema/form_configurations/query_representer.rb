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
    module WorkPackages
      module Schema
        module FormConfigurations
          class QueryRepresenter < ::API::Decorators::Single
            include API::Decorators::LinkedResource

            property :name,
                     exec_context: :decorator

            property :relation_type,
                     exec_context: :decorator

            associated_resource :query,
                                link: ->(*) do
                                  {
                                    href: api_v3_paths.query(query.id),
                                    title: query.name
                                  }
                                end,
                                getter: ->(*) do
                                  next unless embed_links

                                  ::API::V3::Queries::QueryRepresenter.new(query, current_user:)
                                end

            def _type
              if relation_type == ::Relation::TYPE_PARENT
                "WorkPackageFormChildrenQueryGroup"
              else
                "WorkPackageFormRelationQueryGroup"
              end
            end

            def relation_type
              relation_filter&.relation_type
            end

            def relation_filter
              @relation_filter ||= query.filters.detect { |f| f.respond_to? :relation_type }
            end

            def name
              represented.translated_key
            end

            delegate :query, to: :represented
          end
        end
      end
    end
  end
end
