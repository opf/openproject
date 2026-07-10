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

module Wikis
  class WikisController < ApplicationController
    include Layout
    include OpTurbo::ComponentStream
    include PaginationHelper

    before_action :require_login
    no_authorization_required! :index

    def index # rubocop:disable Metrics/AbcSize
      @pages = load_query.results
                         .preload(wiki: :project)
                         .page(page_param)
                         .per_page(per_page_param)

      respond_to do |format|
        format.html do
          render locals: { menu_name: project_or_global_menu }
        end
        format.turbo_stream do
          replace_via_turbo_stream component: Wikis::IndexResultsComponent.new(pages: @pages)
          current_url = url_for(params.permit(:controller, :filters, :sortBy).merge(action: "index"))
          turbo_streams << turbo_stream.push_state(current_url)
          render turbo_stream: turbo_streams
        end
      end
    end

    private

    def load_query
      @query = ParamsToQueryService
                 .new(WikiPage, current_user,
                      query_class: Queries::Wikis::WikiPages::WikiPageQuery)
                 .call(params)
      @query
    end
  end
end
