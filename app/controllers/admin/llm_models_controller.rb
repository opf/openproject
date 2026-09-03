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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  class LlmModelsController < ApplicationController
    include OpTurbo::ComponentStream
    include PaginationHelper

    layout "admin"
    menu_item :llm_models

    before_action :require_feature
    before_action :require_admin
    before_action :set_connection

    def index
      @query = ParamsToQueryService
                 .new(LlmModel, current_user, query_class: Queries::LlmModels::LlmModelQuery)
                 .call(params)
      @models = @query.results.paginate(page: page_param, per_page: per_page_param)
    end

    # Answers the sub-header's filter input, replacing just the table.
    def search
      index

      replace_via_turbo_stream(
        component: LlmConnections::Models::IndexComponent.new(@models, connection: @connection)
      )
      turbo_streams << turbo_stream.push_state(llm_models_path(params.permit(:filters, :page, :per_page)))

      respond_with_turbo_streams
    end

    def refresh
      result = ::LlmConnections::SyncModelsService.new(@connection).call

      flash[result.success? ? :notice : :error] = t(result.success? ? ".success" : ".failure")
      redirect_to llm_models_path, status: :see_other
    end

    private

    def set_connection
      @connection = LlmConnection.instance
    end

    # The flag gates the endpoints, not only the menu entry: an unfinished page
    # must not accept writes just because somebody knows the URL.
    def require_feature
      render_404 unless OpenProject::FeatureDecisions.llm_connection_active?
    end
  end
end
