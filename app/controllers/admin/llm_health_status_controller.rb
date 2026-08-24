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
  class LlmHealthStatusController < ApplicationController
    include OpTurbo::ComponentStream

    layout :admin_or_frame_layout

    before_action :require_feature
    before_action :require_admin
    before_action :find_connection

    menu_item :llm_connection

    def show
      @report = @connection.latest_health_report

      respond_to do |format|
        format.html
        format.text do
          return head :not_found if @report.nil?

          timestamp = @report.created_at.iso8601
          send_data text_report(timestamp),
                    filename: "llm_connection_health_report_#{timestamp}.txt",
                    type: "text/plain",
                    disposition: :attachment
        end
      end
    end

    # A full run, including the billed completion: an administrator clicking
    # "Run checks" is asking whether the connection actually works.
    def create
      run_checks
      redirect_to llm_connection_health_status_report_path, status: :see_other
    end

    def create_health_status_report
      run_checks
      update_via_turbo_stream(component: LlmConnections::SidePanel::HealthStatusComponent.new(@connection))
      respond_with_turbo_streams
    end

    private

    def admin_or_frame_layout
      turbo_frame_request? ? "turbo_rails/frame" : "admin"
    end

    def run_checks
      @connection.deep_health_check = true
      report = Llm::Validators::ConnectionValidator.new(@connection).call
      report.save!
      report
    end

    # Downloaded and pasted into support tickets, so it must not contain the API
    # key or the custom headers -- a gateway header routinely carries a second
    # credential.
    def text_report(timestamp)
      {
        connection: @connection.name,
        configuration: @connection.non_confidential_configuration,
        ran_at: timestamp,
        results: @report ? @report.results.map(&:to_h) : []
      }.to_yaml(stringify_names: true)
    end

    # HealthReports::Validator builds the report through the association, which
    # would insert an unpersisted singleton along with it.
    def find_connection
      @connection = LlmConnection.instance

      redirect_to llm_connection_path unless @connection.persisted?
    end

    # The flag gates the endpoints, not only the menu entry: an unfinished page
    # must not accept writes just because somebody knows the URL.
    def require_feature
      render_404 unless OpenProject::FeatureDecisions.llm_connection_active?
    end
  end
end
