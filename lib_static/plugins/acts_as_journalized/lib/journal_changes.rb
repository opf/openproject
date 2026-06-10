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
      get_custom_comments_changes,
      get_custom_fields_changes,
      get_project_phases_changes,
      get_file_links_changes,
      get_participants_changes,
      get_agenda_items_changes
    ].compact

    @changes = changes.reduce({}.with_indifferent_access, :merge!)
  end

  def get_cause_changes
    return if cause.blank?

    { cause: [nil, cause] }
  end

  def get_data_changes
    ::Acts::Journalized::Differ::Model.changes(predecessor&.data, data)
  end

  def get_attachments_changes
    return unless journable&.attachable?

    ::Acts::Journalized::Differ::Association.new(
      predecessor,
      self,
      association: :attachable_journals,
      id_attribute: :attachment_id,
      multiple_values: :joined
    ).single_attribute_changes(
      :filename,
      key_prefix: "attachments"
    )
  end

  def get_custom_comments_changes
    return unless journable.respond_to?(:custom_comments)

    association = ->(journal) { filter_admin_only_custom_fields(journal.custom_comment_journals) }

    ::Acts::Journalized::Differ::Association.new(
      predecessor,
      self,
      association:,
      id_attribute: :custom_field_id
    ).single_attribute_changes(
      :text,
      key_prefix: "custom_comment"
    )
  end

  def get_custom_fields_changes
    return unless journable&.customizable?

    association = ->(journal) {
      relation = journal.customizable_journals
      if journable.is_a?(::Project)
        relation = relation.with(cf_mappings: journable.project_custom_field_project_mappings)
                           .joins("INNER JOIN cf_mappings USING (custom_field_id)")
      end
      filter_admin_only_custom_fields(relation)
    }

    ::Acts::Journalized::Differ::Association.new(
      predecessor,
      self,
      association:,
      id_attribute: :custom_field_id,
      multiple_values: :joined
    ).single_attribute_changes(
      :value,
      key_prefix: "custom_fields"
    )
  end

  def get_project_phases_changes
    return unless journable.respond_to?(:phases)

    ::Acts::Journalized::Differ::Association.new(
      predecessor,
      self,
      association: :project_phase_journals,
      id_attribute: :phase_id
    ).multiple_attributes_changes(
      %i[active date_range],
      key_prefix: "project_phase"
    )
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

    ::Acts::Journalized::Differ::Association.new(
      predecessor,
      self,
      association: :agenda_item_journals,
      id_attribute: :agenda_item_id,
      multiple_values: :joined
    ).multiple_attributes_changes(
      %i[title duration_in_minutes notes position work_package_id],
      key_prefix: "agenda_items"
    )
  end

  def get_participants_changes
    return unless journable.respond_to?(:participants)

    baseline = participant_baseline_journal
    return unless baseline

    previous = participant_names_for(baseline, :invited)
    current = participant_names_for(self, :invited)

    added = current - previous
    removed = previous - current

    {
      participants_added: participant_change_detail(added),
      participants_removed: participant_change_detail(removed)
    }.compact
  end

  private

  def participant_baseline_journal
    journals = journable.journals.to_a
    current_index = journals.index { |entry| entry.id == id }
    return unless current_index

    journals[0...current_index].reverse.find { |entry| entry.participant_journals.any? }
  end

  def participant_names_for(journal, attribute)
    journal
      .participant_journals
      .select { |entry| entry.public_send(attribute) }
      .filter_map { |entry| entry.user&.name }
      .sort
  end

  def participant_change_detail(names)
    return if names.empty?

    [nil, names.join(", ")]
  end

  def filter_admin_only_custom_fields(relation)
    return relation if User.current.admin?
    return relation unless journable.admin_only_custom_fields_allowed?

    relation.joins(:custom_field).where(custom_fields: { admin_only: false })
  end
end
