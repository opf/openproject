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

class Notification < ApplicationRecord
  REASONS = {
    mentioned: 0,
    assigned: 1,
    watched: 2,
    subscribed: 3,
    commented: 4,
    created: 5,
    processed: 6,
    prioritized: 7,
    scheduled: 8,
    responsible: 9,
    date_alert_start_date: 10,
    date_alert_due_date: 11,
    shared: 12
  }.freeze

  enum reason: REASONS,
       _prefix: true

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :journal
  belongs_to :resource, polymorphic: true

  include Scopes::Scoped
  scopes :unsent_reminders_before,
         :mail_reminder_unsent,
         :mail_alert_unsent,
         :recipient,
         :visible

  def date_alert?
    reason.in?(["date_alert_start_date", "date_alert_due_date"])
  end
end
