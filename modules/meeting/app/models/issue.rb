#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class Issue < ApplicationRecord
  self.table_name = 'issues'

  belongs_to :work_package
  belongs_to :author, class_name: 'User'
  belongs_to :resolved_by, class_name: 'User', optional: true

  # has_many :meeting_agenda_items, dependent: :destroy, class_name: 'MeetingAgendaItem'

  enum issue_type: %i[input_need clarification_need decision_need]

  default_scope { order(updated_at: :desc) }

  scope :open, -> { where(resolved_at: nil) }
  scope :closed, -> { where.not(resolved_at: nil) }

  validates :description, presence: true

  def open?
    resolved_at.nil?
  end

  def closed?
    !open?
  end

  def resolve(user, resolution)
    update(resolved_at: Time.zone.now, resolved_by: user, resolution:)
  end

  def reopen
    update(resolved_at: nil, resolved_by: nil) # leave resolution in place
  end
end
