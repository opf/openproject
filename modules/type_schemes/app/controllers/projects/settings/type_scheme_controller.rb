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

module Projects
  module Settings
    class TypeSchemeController < Projects::SettingsController
      menu_item :settings_type_scheme

      before_action :load_schemes

      def show; end

      def update
        scheme = TypeScheme.active.find_by(id: params[:scheme_id]) if params[:scheme_id].present?
        result =
          if params[:scheme_id].blank?
            ::TypeSchemes::SchemeService.unassign(@project)
          elsif scheme
            ::TypeSchemes::SchemeService.assign(@project, scheme)
          else
            ServiceResult.failure(errors: ActiveModel::Errors.new(ProjectTypeScheme.new).tap { _1.add(:scheme, :inactive) })
          end

        if result.success?
          flash[:notice] = t(:notice_successful_update)
        else
          flash[:error] = result.errors.full_messages.to_sentence
        end
        redirect_to project_settings_type_scheme_path(@project), status: :see_other
      end

      private

      def load_schemes
        @schemes = TypeScheme.active.order(:name)
      end
    end
  end
end
