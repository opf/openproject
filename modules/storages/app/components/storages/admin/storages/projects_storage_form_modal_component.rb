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

module Storages
  module Admin
    module Storages
      class ProjectsStorageFormModalComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable
        include StimulusHelper
        include AngularHelper

        def initialize(project_storage:, last_project_folders: {}, **)
          @project_storage = project_storage
          @last_project_folders = last_project_folders
          super(@project_storage, **)
        end

        private

        attr_reader :project_storage, :storage

        def dialog_id = Storages::ProjectsStorageModalComponent::DIALOG_ID
        def dialog_body_id = Storages::ProjectsStorageModalComponent::DIALOG_BODY_ID

        def url
          if new_record?
            admin_settings_storage_project_storages_path(project_storage.storage)
          else
            admin_settings_storage_project_storage_path(storage_id: project_storage.storage.id, id: project_storage.id)
          end
        end

        def method = new_record? ? :post : :patch

        def help_text
          if new_record?
            I18n.t(:"storages.help_texts.project_folder_bulk")
          else
            I18n.t(:"storages.help_texts.project_folder")
          end
        end

        def aria_label
          new_record? ? I18n.t(:label_add_projects) : I18n.t(:"project_storages.edit_project_folder.label")
        end

        def cancel_button_text
          I18n.t("button_cancel")
        end

        def submit_button_text
          new_record? ? I18n.t("button_add") : I18n.t("button_save")
        end

        delegate :persisted?, :new_record?, to: :project_storage
      end
    end
  end
end
