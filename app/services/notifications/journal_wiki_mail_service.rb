#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Notifications::JournalWikiMailService
  class << self
    def call(journal, send_mails)
      new(journal)
        .call(send_mails)
    end
  end

  attr_reader :journal

  def initialize(journal)
    @journal = journal
  end

  def call(send_mails)
    return unless send_mail?(send_mails)

    if journal.initial?
      send_content_added_mail
    else
      send_content_updated_mail
    end
  end

  private

  def send_mail?(send_mails)
    send_mails && ::UserMailer.perform_deliveries && !journal.noop?
  end

  def send_content_added_mail
    send_content(create_recipients, :wiki_content_added)
  end

  def send_content_updated_mail
    send_content(update_recipients, :wiki_content_updated)
  end

  def notification_disabled?(name)
    !Setting.notified_events.include?(name)
  end

  # Returns the mail addresses of users that should be notified
  def recipients
    project
      .notified_users
      .select { |user| wiki_content.visible?(user) }
  end

  def send_content(recipients, method)
    return if notification_disabled?(method.to_s)

    recipients.uniq.each do |user|
      UserMailer
        .send(method, user, wiki_content, journal_user)
        .deliver_later
    end
  end

  def create_recipients
    recipients +
      wiki.watcher_recipients
  end

  def update_recipients
    recipients +
      wiki.watcher_recipients +
      page.watcher_recipients
  end

  def wiki_content
    journal.journable
  end

  def page
    wiki_content.page
  end

  def wiki
    page.wiki
  end

  def project
    wiki.project
  end

  def journal_user
    journal.user || DeletedUser.first
  end
end
