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

class Announcement < ApplicationRecord
  scope :active,  -> { where(active: true) }
  scope :current, -> { where("show_until >= ?", Date.today) }

  validates :show_until, presence: true

  def self.active_and_current
    active.current.first
  end

  def self.only_one
    a = first
    a = create_default_announcement if a.nil?
    a
  end

  def active_and_current?
    active? && show_until && show_until >= Date.today
  end

  def self.create_default_announcement
    Announcement.create text: "Announcement",
                        show_until: Date.today + 14.days,
                        active: false
  end
end
