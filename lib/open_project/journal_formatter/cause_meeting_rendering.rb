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

module OpenProject::JournalFormatter::CauseMeetingRendering
  private

  def meeting_cause?
    Journal::MEETING_CAUSE_TYPES.include?(cause["type"])
  end

  def hidden_meeting_cause?
    return false unless meeting_cause?

    @meeting = Meeting.find_by(id: cause["meeting_id"])
    @meeting.present? && !@meeting.visible?(User.current)
  end

  def meeting_template_cause?
    meeting_cause? && @meeting&.templated?
  end

  def combined_meeting_message
    text = t("journals.caused_changes.#{caused_change_key}_html", meeting_title_information: meeting_message)
    html? ? text : strip_tags(text)
  end

  def meeting_message
    return I18n.t("journals.cause_descriptions.meeting_deleted") if @meeting.nil?
    return meeting_template_message if @meeting.templated?

    label = "#{@meeting.title} – #{format_time(@meeting.start_time)}"
    return meeting_link(label) unless @meeting.cancelled?

    "#{label} #{I18n.t('journals.cause_descriptions.meeting_cancelled')}"
  end

  def meeting_template_message
    t("journals.cause_descriptions.#{template_description_key}_html", link: meeting_link(@meeting.title))
  end

  def meeting_link(label)
    return label unless html?

    link_to(label, meeting_path(link_target_meeting, anchor: agenda_item_anchor))
  end

  def link_target_meeting
    return @meeting unless backlog_move?

    Meeting.find_by(id: cause["source_meeting_id"]) || @meeting
  end

  def backlog_move?
    cause["type"] == "meeting_agenda_item_moved" && @meeting.series_template?
  end

  def agenda_item_anchor
    return if @journal.journable_id.blank?

    agenda_item_id =
      case cause["type"]
      when "meeting_agenda_item_removed" then nil
      when "meeting_outcome_recorded" then outcome_parent_agenda_item_id
      else own_agenda_item_id
      end

    "meeting-agenda-item-#{agenda_item_id}" if agenda_item_id
  end

  def own_agenda_item_id
    MeetingAgendaItem.where(meeting_id: @meeting.id, work_package_id: @journal.journable_id).pick(:id)
  end

  def outcome_parent_agenda_item_id
    MeetingOutcome
      .joins(:meeting_agenda_item)
      .where(work_package_id: @journal.journable_id, meeting_agenda_items: { meeting_id: @meeting.id })
      .pick(:meeting_agenda_item_id)
  end

  def template_description_key
    return "meeting_template" unless @meeting.series_template?

    backlog_move? ? "meeting_series_backlog" : "meeting_series_template"
  end
end
