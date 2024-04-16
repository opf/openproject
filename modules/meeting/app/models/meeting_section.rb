#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class MeetingSection < ApplicationRecord
  self.table_name = "meeting_sections"

  belongs_to :meeting

  has_many :agenda_items, dependent: :destroy, class_name: "MeetingAgendaItem"
  has_one :project, through: :meeting

  validates :name, presence: true

  before_validation :set_default_name

  acts_as_list scope: :meeting

  default_scope { order(:position) }

  def set_default_name
    if name.blank?
      self.name = "Untitled" # TODO: I18n
    end
  end

  def has_default_name?
    name == "Untitled" # TODO: I18n
  end

  def editable?
    !meeting&.closed?
  end

  def modifiable?
    !meeting&.closed?
  end

  def agenda_items_sum_duration_in_minutes
    agenda_items.sum(:duration_in_minutes)
  end
end
