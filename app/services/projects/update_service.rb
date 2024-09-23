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
  class UpdateService < ::BaseServices::Update
    prepend Projects::Concerns::UpdateDemoData

    private

    attr_accessor :memoized_changes

    def set_attributes(params)
      ret = super

      # Because awesome_nested_set reloads the model after saving, we cannot rely
      # on saved_changes.
      self.memoized_changes = model.changes

      ret
    end

    def after_perform(service_call)
      ret = super
      reset_section_scoped_validation
      touch_on_custom_values_update
      notify_on_identifier_renamed
      send_update_notification
      update_wp_versions_on_parent_change
      handle_archiving

      ret
    end

    def touch_on_custom_values_update
      model.touch if only_custom_values_updated?
    end

    def notify_on_identifier_renamed
      return unless memoized_changes["identifier"]

      OpenProject::Notifications.send(OpenProject::Events::PROJECT_RENAMED, project: model)
    end

    def send_update_notification
      OpenProject::Notifications.send(OpenProject::Events::PROJECT_UPDATED, project: model)
    end

    def only_custom_values_updated?
      !model.saved_changes? && model.custom_values.any?(&:saved_changes?)
    end

    def update_wp_versions_on_parent_change
      return unless memoized_changes["parent_id"]

      WorkPackage.update_versions_from_hierarchy_change(model)
    end

    def handle_archiving
      return unless model.saved_change_to_active?

      service_class =
        if model.active?
          # was unarchived
          Projects::UnarchiveService
        else
          # was archived
          Projects::ArchiveService
        end

      # EmptyContract is used because archive/unarchive conditions have
      # already been checked in Projects::UpdateContract
      service = service_class.new(user:, model:, contract_class: EmptyContract)
      service.call
    end

    def reset_section_scoped_validation
      # Reset the section scope after saving in order to not silently
      # carry this setting in this instance.
      model._limit_custom_fields_validation_to_section_id = nil
    end
  end
end
