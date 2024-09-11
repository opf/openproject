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

module Storages::ProjectStorages::NotificationsService
  module_function

  %i[created updated destroyed].each do |event|
    define_method :"broadcast_project_storage_#{event}" do |project_storage:|
      broadcast(event:, project_storage:)
    end
  end

  def broadcast(event:, project_storage:)
    broadcast_raw event:, project_folder_mode: project_storage.project_folder_mode.to_sym,
                  project_folder_mode_previously_was: project_storage.project_folder_mode_previously_was&.to_sym,
                  storage: project_storage.storage
  end

  def broadcast_raw(event:, project_folder_mode:, project_folder_mode_previously_was:, storage:)
    OpenProject::Notifications.send(
      "OpenProject::Events::PROJECT_STORAGE_#{event.to_s.upcase}".constantize,
      project_folder_mode:,
      project_folder_mode_previously_was:,
      storage:
    )
  end

  def automatic_folder_mode_broadcast?(broadcasted_payload)
    folder_modes = broadcasted_payload.values_at(:project_folder_mode, :project_folder_mode_previously_was).compact
    folder_modes.map { |mode| mode&.to_sym }.any?(:automatic)
  end
end
