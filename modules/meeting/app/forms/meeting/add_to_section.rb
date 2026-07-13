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

class Meeting::AddToSection < ApplicationForm
  form do |meeting_form|
    meeting_form.autocompleter(
      name: :meeting_section_id,
      label: I18n.t("label_add_work_package_to_meeting_section_label"),
      caption:,
      input_width:,
      autocomplete_options: {
        decorated: true,
        defaultData: false,
        multiple: false,
        disabled: meeting.blank?,
        placeholder: placeholder_text,
        append_to: append_to_container,
        openDirectly: @move_to_section
      }
    ) do |select|
      items.each do |item|
        select.option(
          value: item.id,
          label: option_title(item),
          selected: preselected_option.present? && item.id == preselected_option[:id]
        )
      end
    end
  end

  def initialize(wrapper_id: nil, occurrence: nil, item: nil, move_to_section: true)
    super()

    @wrapper_id = wrapper_id
    @occurrence = meeting == occurrence ? nil : occurrence
    @selected_section = item&.meeting_section
    @move_to_section = move_to_section
  end

  private

  delegate :meeting, to: :model

  def append_to_container
    @wrapper_id.nil? ? "body" : "##{@wrapper_id}"
  end

  def items # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    items = []

    items.concat(meeting.sections) if meeting.present? && @occurrence.nil?
    items.concat(@occurrence.sections) if @occurrence.present?
    items.push(MeetingSection.new) if items.empty?
    items.push(meeting.backlog) if meeting.present? && !meeting.template? && meeting.backlog.present?

    items.reject! { |i| i == @selected_section } if @selected_section.present?

    items
  end

  def option_title(item)
    return I18n.t("meeting_section.untitled_title") if item.title.blank? && !item.backlog?

    item.title
  end

  def preselected_option
    return if meeting.blank?

    if meeting.recurring?
      without_backlog = items.reject(&:backlog?)
      item = without_backlog.last
    else
      item = meeting.backlog
    end

    item
  end

  def any_non_backlog_sections?
    meeting.sections.none? || (meeting.sections.many? && meeting.sections.first.title.blank?)
  end

  def placeholder_text
    I18n.t("placeholder_section_select_meeting_first") if meeting.blank?
  end

  def caption
    I18n.t("label_section_selection_caption") unless @move_to_section
  end

  def input_width
    @move_to_section ? nil : :large
  end
end
