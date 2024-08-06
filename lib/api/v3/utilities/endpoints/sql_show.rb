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
      module Endpoints
        class SqlShow
          def initialize(model:)
            self.model = model
          end

          def mount
            show = self

            -> do
              scope = show.scope(params)

              show.check_visibility(scope)
              show.render(scope)
            end
          end

          def scope(params)
            query_class.new(user: User.current)
                       .where("id", "=", params[:id])
                       .results
          end

          def check_visibility(scope)
            raise ::API::Errors::NotFound.new unless scope.exists?
          end

          def render(scope)
            ::API::V3::Utilities::SqlRepresenterWalker
              .new(scope.limit(1),
                   current_user: User.current,
                   url_query: { select: { "*" => {} } })
              .walk(render_representer)
          end

          attr_accessor :model,
                        :api_name

          private

          def render_representer
            "API::V3::#{model.name.pluralize}::#{model.name}SqlRepresenter".constantize
          end

          def query_class
            "Queries::#{model.name.pluralize}::#{model.name}Query".constantize
          end
        end
      end
    end
  end
end
