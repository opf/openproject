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

class MeetingSection < ApplicationRecord
  self.table_name = "meeting_sections"

  belongs_to :meeting

  has_many :agenda_items, dependent: :destroy, class_name: "MeetingAgendaItem"
  has_one :project, through: :meeting

  acts_as_list scope: [:meeting_id, { backlog: false }]

  default_scope { order(:position) }

  scope :backlog, -> { where(backlog: true) }

  def title
    return super unless backlog?

    meeting.recurring? ? I18n.t(:label_series_backlog) : I18n.t(:label_agenda_backlog)
  end

  def untitled?
    title.blank?
  end

  def editable?
    !meeting&.closed?
  end

  def agenda_items_sum_duration_in_minutes
    agenda_items.sum(:duration_in_minutes)
  end

  def last_position
    if agenda_items.empty?
      1
    else
      agenda_items.maximum(:position) + 1
    end
  end
end
