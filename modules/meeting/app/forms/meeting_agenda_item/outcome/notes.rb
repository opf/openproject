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

class MeetingAgendaItem::Outcome::Notes < ApplicationForm
  delegate :object, to: :@builder

  form do |outcome_form|
    outcome_form.rich_text_area(
      name: :notes,
      label:,
      classes: "ck-editor-primer-adjusted",
      rich_text_options: {
        resource:,
        editor_type: "constrained",
        storageKey: "meeting-agenda-#{object.meeting_agenda_item&.id || 'new'}-outcome-#{object.id || 'new'}",
        showAttachments: false
      }
    )
  end

  def resource
    return unless object&.meeting_agenda_item

    API::V3::Meetings::MeetingRepresenter
      .new(object.meeting_agenda_item.meeting, current_user: User.current, embed_links: false)
  end

  private

  def label
    if object.persisted?
      I18n.t(:label_agenda_outcome_edit)
    else
      I18n.t(:label_agenda_new_outcome)
    end
  end
end
