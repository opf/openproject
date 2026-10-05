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
    class FieldRuleSchemeController < Projects::SettingsController
      menu_item :settings_field_rule_scheme

      def show
        @schemes = FieldRuleScheme.active.order(:name)
        @current = ProjectFieldRuleScheme.find_by(project_id: @project.id)&.scheme
      end

      def update
        scheme_id = params[:scheme_id]
        result =
          if scheme_id.blank?
            ::FieldRules::SchemeService.unassign(@project)
          else
            scheme = FieldRuleScheme.active.find_by(id: Integer(scheme_id.to_s, exception: false))
            if scheme
              ::FieldRules::SchemeService.assign(@project, scheme)
            else
              ServiceResult.failure(errors: ActiveModel::Errors.new(ProjectFieldRuleScheme.new).tap { _1.add(:scheme, :inactive) })
            end
          end

        if result.success?
          flash[:notice] = t(:notice_successful_update)
        else
          flash[:error] = result.errors.full_messages.to_sentence
        end
        redirect_to project_settings_field_rule_scheme_path(@project), status: :see_other
      end
    end
  end
end
