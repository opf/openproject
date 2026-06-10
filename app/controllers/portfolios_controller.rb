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

# Controller for items of workspace_type portfolio. Contains special logic that is unique to portfolios.
#
# Note that _some_ actions (such as #new) are handled by the project controller since portfolios behave mostly like
# projects in these cases.
class PortfoliosController < ProjectsController
  before_action :authorize_portfolio_access, only: %i[index]

  skip_before_action :load_query_or_deny_access # skip using the superclass's before action because the next must be called first
  before_action :set_default_query, only: %i[index] # Must be called before `load_query_or_deny_access`
  before_action :load_query_or_deny_access, only: %i[index]

  current_menu_item :index do
    :portfolios
  end

  def index # rubocop:disable Metrics/AbcSize
    respond_to do |format|
      format.html do
        flash.now[:error] = @query.errors.full_messages if @query.errors.any?

        render layout: "global", locals: { query: @query, state: :show }
      end

      format.turbo_stream do
        replace_via_turbo_stream(
          component: Portfolios::IndexPageHeaderComponent.new(query: @query, current_user:, params:)
        )
        update_via_turbo_stream(
          component: Projects::ProjectFilterButtonComponent.new(query: @query, disable_buttons: false)
        )
        replace_via_turbo_stream(component: Portfolios::IndexComponent.new(query: @query, current_user:))

        current_url = url_for(params.permit(:controller, :action, :query_id, :filters, :sortBy, :page, :per_page))
        turbo_streams << turbo_stream.push_state(current_url)
        turbo_streams << turbo_stream.turbo_frame_set_src(
          "portfolios_sidemenu",
          portfolios_menu_url(query_id: @query.id, controller_path: "portfolios")
        )

        turbo_streams << turbo_stream.replace("flash-messages", helpers.render_flash_messages)

        render turbo_stream: turbo_streams
      end
    end
  end

  private

  def set_default_query
    # When loading the default query (when users enter the page without making a query selection),
    # we want to ensure that we get a portfolio query. Else, users would see a project query.
    params[:query_id] ||= ProjectQueries::Static::ACTIVE_PORTFOLIOS
  end

  def authorize_portfolio_access
    render_403 unless User.current.allowed_globally?(:add_portfolios) ||
                       Project.portfolio.allowed_to(User.current, :view_project).any?
  end

  # Overwrite method in Queries::Loading
  # since default doesn't work with portfolios using ProjectQuery
  def query_class
    ::ProjectQuery
  end
end
