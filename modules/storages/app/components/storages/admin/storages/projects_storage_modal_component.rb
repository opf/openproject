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
      class ProjectsStorageModalComponent < ApplicationComponent
        include OpTurbo::Streamable

        DIALOG_ID = "storages--projects-storage-modal".freeze
        DIALOG_BODY_ID = "storages--projects-storage-modal-body".freeze

        def initialize(project_storage:, last_project_folders:, **)
          @project_storage = project_storage
          @storage = project_storage.storage
          @last_project_folders = last_project_folders

          super(@project_storage, **)
        end

        private

        def dialog_id = DIALOG_ID
        def dialog_body_id = DIALOG_BODY_ID

        attr_reader :project_storage, :storage, :last_project_folders

        def title
          if new_record?
            I18n.t(:label_add_projects)
          else
            I18n.t(:"storages.label_project_folder")
          end
        end

        delegate :new_record?, to: :project_storage
      end
    end
  end
end
