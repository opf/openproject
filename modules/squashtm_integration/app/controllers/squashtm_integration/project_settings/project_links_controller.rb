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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module SquashTMIntegration
  module ProjectSettings
    class ProjectLinksController < ::Projects::SettingsController
      include OpTurbo::ComponentStream

      menu_item :settings_squashtm

      before_action :set_server
      before_action :set_project_link
      before_action :require_persisted_project_link, only: %i[destroy_dialog destroy]

      helper_method :linked_squashtm_project_missing?, :linked_squashtm_project_name

      def show
        load_squashtm_projects
      end

      def update
        attributes = params.expect(squashtm_project_link: %i[squashtm_project_id]).to_h.symbolize_keys
        result = save_project_link(attributes)

        if result.success?
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to_settings
        else
          @project_link = result.result
          load_squashtm_projects
          render :show, status: :unprocessable_entity
        end
      end

      def destroy_dialog
        respond_with_dialog DeleteProjectLinkDialogComponent.new(@project_link)
      end

      def destroy
        result = ProjectLinks::DeleteService.new(user: current_user, model: @project_link).call

        if result.success?
          flash[:notice] = t(".success")
        else
          flash[:error] = result.errors.full_messages.to_sentence
        end

        redirect_to_settings
      end

      private

      def redirect_to_settings
        redirect_to project_settings_squashtm_path(@project), status: :see_other
      end

      def set_server
        @server = Server.first
      end

      def set_project_link
        @project_link = ProjectLink.find_or_initialize_by(project: @project)
      end

      def require_persisted_project_link
        render_404 unless @project_link.persisted?
      end

      def save_project_link(attributes)
        if @project_link.persisted?
          ProjectLinks::UpdateService.new(user: current_user, model: @project_link).call(attributes)
        else
          ProjectLinks::CreateService.new(user: current_user).call(attributes.merge(project: @project))
        end
      end

      def linked_squashtm_project_missing?
        return false unless @project_link.persisted? && @squashtm_projects

        @squashtm_projects.none? { |squashtm_project| squashtm_project[:id] == @project_link.squashtm_project_id_in_database }
      end

      def linked_squashtm_project_name
        name = @project_link.squashtm_project_name_in_database
        return name if @server.nil?

        helpers.render(
          Primer::Beta::Link.new(
            href: @server.project_url(@project_link.squashtm_project_id_in_database),
            target: "_blank",
            rel: "noopener noreferrer"
          )
        ) do |link|
          link.with_trailing_visual_icon(icon: :"link-external")
          name
        end
      end

      def load_squashtm_projects
        return if @server.nil?

        @squashtm_projects = Client.for(@server).all_projects
                                   .map { |squashtm_project| squashtm_project.slice("id", "name").symbolize_keys }
                                   .sort_by { |squashtm_project| squashtm_project[:name].to_s.downcase }
      rescue Client::Error => e
        Rails.logger.warn("SquashTM projects could not be loaded: #{e.class}: #{e.message}")
        @squashtm_projects = nil
      end
    end
  end
end
