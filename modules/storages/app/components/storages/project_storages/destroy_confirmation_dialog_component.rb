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

# This components renders a dialog to confirm the deletion of a project from a storage.
module Storages::ProjectStorages
  class DestroyConfirmationDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(storage:, project_storage:)
      super

      @storage = storage
      @project_storage = project_storage
    end

    def id
      "project-storage-#{@project_storage.id}-destroy-confirmation-dialog"
    end

    def heading
      I18n.t("project_storages.remove_project.dialog.heading_text", storage: @storage.name)
    end

    def text
      text = I18n.t("project_storages.remove_project.dialog.text")
      if @project_storage.project_folder_mode == "automatic"
        text << " "
        text << I18n.t("project_storages.remove_project.dialog.automatically_managed_appendix")
      end
      text
    end

    def confirmation_text
      I18n.t("project_storages.remove_project.dialog.confirmation_text")
    end
  end
end
