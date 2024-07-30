# -- copyright
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
# ++
module Projects
  module QueryLoading
    private

    def load_query(duplicate:)
      ::Queries::Projects::Factory.find(params[:query_id],
                                        params: permitted_query_params,
                                        user: current_user,
                                        duplicate:)
    end

    def load_query_or_deny_access
      @query = load_query(duplicate: false)

      render_403 unless @query
    end

    def build_query_or_deny_access
      @query = load_query(duplicate: true)

      render_403 unless @query
    end

    def permitted_query_params
      query_params = {}

      if params[:query]
        query_params.merge!(params.require(:query).permit(:name))
      end

      query_params.merge!(::Queries::ParamsParser.parse(params))

      query_params.with_indifferent_access
    end
  end
end
