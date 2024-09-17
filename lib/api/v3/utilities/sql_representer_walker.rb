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
    module Utilities
      class SqlRepresenterWalker
        include API::Utilities::UrlPropsParsingHelper

        def initialize(scope,
                       current_user:,
                       url_query: {},
                       self_path: nil)
          self.scope = scope
          self.current_user = current_user
          self.self_path = self_path
          # Hard wiring the properties to embed is a work around until signaling the properties to embed is implemented
          self.url_query = url_query.merge(embed: { "elements" => {} })
        end

        def walk(start)
          result = SqlWalkerResults.new(scope,
                                        url_query:,
                                        self_path:)

          result.selects = embedded_depth_first([], start) do |map, stack, current_representer|
            result.replace_map.merge!(map)

            current_representer.select_sql(select_for(stack), result)
          end

          embedded_depth_first([], start) do |_, stack, current_representer|
            result.projection_scope = current_representer.joins(select_for(stack), result.projection_scope)
          end

          embedded_depth_first([], start) do |_, _, current_representer|
            result.ctes.merge!(current_representer.ctes(result))
          end

          self.sql = start.to_sql(result)

          self
        end

        def to_json(*)
          ActiveRecord::Base.connection.select_one(sql)["json"]
        end

        protected

        attr_accessor :scope,
                      :current_user,
                      :sql,
                      :url_query,
                      :self_path

        def embed
          url_query[:embed]
        end

        def select
          url_query[:select]
        end

        def embedded_depth_first(stack, current_representer, &)
          up_map = {}

          embed_for(stack).each_key do |key|
            representer = current_representer
                          .embed_map[key]

            up_map[key] = embedded_depth_first(stack.dup << key, representer, &)
          end

          yield up_map, stack, current_representer if select_for(stack)
        end

        def select_for(stack)
          stack.any? ? select.dig(*stack) : select
        end

        def embed_for(stacker)
          stacker.any? ? embed.dig(*stacker) : embed
        end
      end
    end
  end
end
