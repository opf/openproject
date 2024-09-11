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

class Mails::WatcherJob < Mails::DeliverJob
  include Mails::WithSender

  def perform(watcher, watcher_changer)
    self.watcher = watcher

    super(watcher.user, watcher_changer)
  end

  def render_mail
    WorkPackageMailer
      .watcher_changed(watcher.watchable,
                       recipient,
                       sender,
                       action)
  end

  private

  attr_accessor :watcher

  def abort?
    super || !notify_about_watcher_changed?
  end

  def notify_about_watcher_changed?
    return false if self_watching?
    return false unless UserMailer.perform_deliveries

    settings = watcher
               .user
               .notification_settings
               .applicable(watcher.watchable.project)
               .first

    return false if settings.nil?

    settings.watched
  end

  def self_watching?
    watcher.user == sender
  end

  def action
    raise NotImplementedError, "subclass responsibility"
  end
end
