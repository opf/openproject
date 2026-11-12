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

# Destroy confirmation dialog used when removing a storage from a project from within the project
# by going to "Some project" -> Project settings -> Files.
module Storages
  module ProjectStorages
    class DestroyConfirmationDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      TEST_SELECTOR = "op-project-storages--delete-dialog"

      # @param target [Symbol] The submission target of the dialog's form. One of :project or :storage
      # @param target_page [String, Integer] An optional page query parameter for the target that the form will submit to.
      def initialize(project_storage:, target:, target_page: nil)
        super
        @project_storage = project_storage
        @target = target
        @target_page = target_page
      end

      private

      def form_arguments
        {
          action: target_path,
          method: :delete
        }
      end

      def target_path
        case @target
        when :project
          project_settings_project_storage_path(project_id: @project_storage.project, id: @project_storage, page: @target_page)
        when :storage
          admin_settings_storage_project_storage_path(id: @project_storage, page: @target_page)
        else
          raise ArgumentError, "Unsupported target #{@target} for #{self.class}"
        end
      end
    end
  end
end
