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

module JournalChanges
  def get_changes
    return @changes if @changes
    return {} if data.nil?

    changes = [
      get_cause_changes,
      get_data_changes,
      get_attachments_changes,
      get_custom_fields_changes,
      get_file_links_changes,
      get_agenda_items_changes
    ].compact

    @changes = changes.reduce({}.with_indifferent_access, :merge!)
  end

  def get_cause_changes
    return if cause.blank?

    { cause: [nil, cause] }
  end

  def get_data_changes
    ::Acts::Journalized::JournableDiffer.changes(predecessor&.data, data)
  end

  def get_attachments_changes
    return unless journable&.attachable?

    ::Acts::Journalized::JournableDiffer.association_changes(
      predecessor,
      self,
      "attachable_journals",
      "attachments",
      :attachment_id,
      :filename
    )
  end

  def get_custom_fields_changes
    return unless journable&.customizable?

    customizable_changes = ::Acts::Journalized::JournableDiffer.association_changes(
      predecessor,
      self,
      "customizable_journals",
      "custom_fields",
      :custom_field_id,
      :value
    )

    if journable.class.name == "Project"
      remove_disabled_project_custom_fields!(customizable_changes)
    end

    customizable_changes
  end

  def get_file_links_changes
    return unless has_file_links?

    ::Acts::Journalized::FileLinkJournalDiffer.get_changes_to_file_links(
      predecessor,
      storable_journals
    )
  end

  def get_agenda_items_changes
    return unless journable.respond_to?(:agenda_items)

    ::Acts::Journalized::JournableDiffer.association_changes_multiple_attributes(
      predecessor,
      self,
      "agenda_item_journals",
      "agenda_items",
      :agenda_item_id,
      %i[title duration_in_minutes notes position work_package_id]
    )
  end

  private

  def remove_disabled_project_custom_fields!(customizable_changes)
    allowed_custom_field_keys = journable
      .project_custom_field_project_mappings
      .map { |c| "custom_fields_#{c.custom_field_id}" }

    customizable_changes.delete_if { |key| !key.in?(allowed_custom_field_keys) }
  end
end
