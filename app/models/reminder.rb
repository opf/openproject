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

class Reminder < ApplicationRecord
  belongs_to :remindable, polymorphic: true
  belongs_to :creator, class_name: "User"

  has_many :reminder_notifications, dependent: :destroy
  has_many :notifications, through: :reminder_notifications

  # Currently, reminders are personal, meaning
  # they are only visible to the user who created them
  # and who still has access to the remindable.
  def self.visible(user)
    where(creator: user)
      .where(remindable_type: WorkPackage.name, remindable_id: WorkPackage.visible(user).select(:id))
  end

  def self.upcoming_and_visible_to(user)
    visible(user)
      .where(completed_at: nil)
      .where.missing(:reminder_notifications)
  end

  def visible?(user = User.current)
    creator == user && remindable.visible?(user)
  end

  def unread_notifications?
    unread_notifications.exists?
  end

  def unread_notifications
    notifications.where(read_ian: [false, nil])
  end

  def completed?
    completed_at.present?
  end

  def scheduled?
    job_id.present? && !completed?
  end
end
