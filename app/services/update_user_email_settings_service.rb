#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

UpdateUserEmailSettingsService = Struct.new(:user) do
  def call(mail_notification: nil,
           self_notified: nil,
           notified_project_ids: [])

    set_mail_notification(mail_notification)
    set_self_notified(self_notified)

    ret_value = false

    user.transaction do
      if (ret_value = user.save && user.pref.save)
        set_notified_project_ids(notified_project_ids)
      end
    end

    ret_value
  end

  private

  def set_mail_notification(mail_notification)
    user.mail_notification = mail_notification unless mail_notification.nil?
  end

  def set_self_notified(self_notified)
    user.pref.self_notified = self_notified unless self_notified.nil?
  end

  def set_notified_project_ids(notified_project_ids)
    user.notified_project_ids = notified_project_ids if user.mail_notification == 'selected'
  end
end
