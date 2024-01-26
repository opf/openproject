# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++
module Projects
  module QueryLoading
    def load_query(existing: true)
      query = if existing
                Queries::Projects::Factory.find(params[:query_id])
              else
                Queries::Projects::ProjectQuery.new
              end

      contract_class = if existing
                         # This one allows to change the name of the query.
                         # Semantically, it would be better to use the UpdateContract
                         # but there wasn't the need to create that yet and for now it
                         # would be the same as the CreateContract anyway.
                         Queries::Projects::ProjectQueries::CreateContract
                       else
                         Queries::Projects::ProjectQueries::LoadingContract
                       end

      Queries::Projects::ProjectQueries::SetAttributesService
        .new(user: current_user,
             model: query,
             contract_class:)
        .call(permitted_query_params)
    end

    private

    def permitted_query_params
      query_params = if params[:query]
                       params
                         .require(:query)
                         .permit(:name)
                         .to_h
                     else
                       {}
                     end

      query_params.merge!(Queries::ParamsParser.parse(params))

      query_params.with_indifferent_access
    end
  end
end
