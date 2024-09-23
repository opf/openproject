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
        class SqlIndex < Index
          private

          def render_paginated_success(results, query, params, self_path)
            resulting_params = calculate_resulting_params(query, params)

            ::API::V3::Utilities::SqlRepresenterWalker
              .new(results,
                   current_user: User.current,
                   self_path:,
                   url_query: resulting_params)
              .walk(deduce_render_representer)
          end

          def paginated_representer?
            true
          end

          def deduce_render_representer
            "::API::V3::#{deduce_api_namespace}::#{api_name}SqlCollectionRepresenter".constantize
          end

          def calculate_resulting_params(query, provided_params)
            super.tap do |params|
              params[:select] = nested_from_csv(provided_params["select"]) || { "*" => {}, "elements" => { "*" => {} } }
            end
          end
        end
      end
    end
  end
end
