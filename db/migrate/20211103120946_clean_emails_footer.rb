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

class CleanEmailsFooter < ActiveRecord::Migration[6.1]
  def up
    return unless Setting.where(name: "emails_footer").exists? # rubocop:disable Rails/WhereExists

    Setting.reset_column_information
    filtered_footer = Setting
      .emails_footer
      .reject do |locale, text|
      if assumed_notification_text?(text)
        warn "Removing emails footer for #{locale} as it matches the default notification syntax."
        true
      end
    end

    if filtered_footer.length < Setting.emails_footer.length
      Setting.emails_footer = filtered_footer
    end
  end

  def down
    # Nothing to migrate
  end

  private

  def assumed_notification_text?(text)
    [
      "You have received this notification because of your notification settings",
      "You have received this notification because you have either subscribed to it, or are involved in it.",
      "Sie erhalten diese E-Mail aufgrund Ihrer Benachrichtungseinstellungen",
      "/my/account",
      "/my/notifications",
      '/my/mail\_notifications'
    ].any? { |val| text.include?(val) }
  end
end
