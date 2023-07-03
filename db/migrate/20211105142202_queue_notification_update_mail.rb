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

class QueueNotificationUpdateMail < ActiveRecord::Migration[6.1]
  def up
    # On a newly created database, we don't want the update mail to be sent.
    # Users are only created upon seeding.
    return unless User.not_builtin.exists?

    ::Announcements::SchedulerJob
      .perform_later subject: :'notifications.update_info_mail.subject',
                     body: :'notifications.update_info_mail.body',
                     body_header: :'notifications.update_info_mail.body_header',
                     body_subheader: :'notifications.update_info_mail.body_subheader'
  end
end
