# frozen_string_literal: true

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
    module AllocatablePrincipals
      # The principals an allocation can be made out to: users and the
      # placeholder users standing for a set of them, searchable in one picker.
      # `filters=[{"allocatable_in_project":{"operator":"=","values":["42"]}}]`
      # narrows the users to a project's members.
      class AllocatablePrincipalsAPI < ::API::OpenProjectAPI
        # The query is not the one deduced from the model, as `Principal`'s
        # visibility rules would drop the placeholders again.
        class Index < ::API::V3::Utilities::Endpoints::Index
          def parse(request)
            ::API::V3::ParamsToQueryService
              .new(model,
                   request.current_user,
                   query_class: ::Queries::Principals::AllocatablePrincipalQuery)
              .call(request.params)
          end
        end

        resources :allocatable_principals do
          get &Index
            .new(model: Principal, self_path: "allocatable_principals")
            .mount
        end
      end
    end
  end
end
