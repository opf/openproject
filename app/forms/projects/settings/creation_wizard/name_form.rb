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

module Projects
  module Settings
    module CreationWizard
      class NameForm < ApplicationForm
        form do |f|
          f.select_list(
            name: :project_creation_wizard_artifact_name,
            label: I18n.t("settings.project_initiation_request.name.artifact_name"),
            caption: I18n.t("settings.project_initiation_request.name.artifact_name_caption"),
            required: true,
            input_width: :large
          ) do |list|
            ::Projects::CreationWizard::ARTIFACT_NAME_OPTIONS.each do |id|
              list.option(
                value: id,
                label: I18n.t("settings.project_initiation_request.name.options.#{id}"),
                selected: id == model.project_creation_wizard_artifact_name
              )
            end
          end

          f.submit(
            name: :submit,
            label: I18n.t("button_save"),
            scheme: :primary
          )
        end
      end
    end
  end
end
