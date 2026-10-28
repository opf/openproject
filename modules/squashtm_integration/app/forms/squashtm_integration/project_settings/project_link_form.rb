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
    class ProjectLinkForm < ApplicationForm
      form do |f|
        f.select_list(
          name: :squashtm_project_id,
          label: attribute_name(:squashtm_project_id),
          caption: I18n.t("squashtm_integration.project_settings.project_link_form.squashtm_project_caption"),
          include_blank: I18n.t("squashtm_integration.project_settings.project_link_form.squashtm_project_prompt"),
          input_width: :large
        ) do |list|
          @squashtm_projects.each do |squashtm_project|
            list.option(
              value: squashtm_project[:id],
              label: squashtm_project[:name],
              selected: squashtm_project[:id] == model.squashtm_project_id
            )
          end
        end

        f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
      end

      def initialize(squashtm_projects:)
        super()
        @squashtm_projects = squashtm_projects
      end
    end
  end
end
