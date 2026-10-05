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
# frozen_string_literal: true

module Projects
  module Settings
    class ScreenSchemeController < Projects::SettingsController
      menu_item :settings_screen_scheme

      def show
        @schemes = ScreenScheme.active.order(:name)
        @assignment = ProjectScreenScheme.includes(:scheme).find_by(project_id: @project.id)
        @current = @assignment&.scheme
        @matrix = ::Screens::Resolver.matrix(@project)
        @types = @project.enabled_types.order(:position)
        @selected_type = selected_type
        @preview = @selected_type ? ::Screens::Resolver.for(@project, @selected_type, :create) : nil
      end

      def update
        scheme_id = params[:scheme_id]
        result =
          if scheme_id.blank?
            ::Screens::SchemeService.unassign(@project)
          else
            scheme = ScreenScheme.active.find_by(id: Integer(scheme_id.to_s, exception: false))
            if scheme
              ::Screens::SchemeService.assign(@project, scheme)
            else
              ServiceResult.failure(errors: ActiveModel::Errors.new(ProjectScreenScheme.new).tap { _1.add(:scheme, :inactive) })
            end
          end

        if result.success?
          flash[:notice] = t(:notice_successful_update)
        else
          flash[:error] = result.errors.full_messages.to_sentence
        end
        redirect_to project_settings_screen_scheme_path(@project), status: :see_other
      end

      private

      def selected_type
        if params[:type_id].present?
          @project.enabled_types.find_by(id: params[:type_id])
        else
          @project.enabled_types.order(:position).first
        end
      end
    end
  end
end
