#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'zlib'

class WikiContent < ApplicationRecord
  belongs_to :page, class_name: 'WikiPage', foreign_key: 'page_id'
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  validates_length_of :comments, maximum: 255, allow_nil: true

  attr_accessor :comments

  before_save :comments_to_journal_notes
  after_create :send_content_added_mail
  after_update :send_content_updated_mail, if: :saved_change_to_text?

  acts_as_journalized

  acts_as_event type: 'wiki-page',
                title: Proc.new { |o| "#{l(:label_wiki_edit)}: #{o.journal.journable.page.title} (##{o.journal.journable.version})" },
                url: Proc.new { |o| { controller: '/wiki', action: 'show', id: o.journal.journable.page, project_id: o.journal.journable.page.wiki.project, version: o.journal.journable.version } }

  def activity_type
    'wiki_edits'
  end

  def visible?(user = User.current)
    page.visible?(user)
  end

  def project
    page.project
  end

  def attachments
    page.nil? ? [] : page.attachments
  end

  def text=(value)
    super value.presence || ''
  end

  # Returns the mail adresses of users that should be notified
  def recipients
    notified = project.notified_users
    notified.select { |user| visible?(user) }
  end

  # FIXME: Deprecate
  def versions
    journals
  end

  # REVIEW
  def version
    last_journal.nil? ? 0 : last_journal.version
  end

  private

  def comments_to_journal_notes
    add_journal author, comments
  end

  def send_content_added_mail
    return unless Setting.notified_events.include?('wiki_content_added')

    create_recipients.uniq.each do |user|
      UserMailer.wiki_content_added(user, self, User.current).deliver_later
    end
  end

  def send_content_updated_mail
    return unless Setting.notified_events.include?('wiki_content_updated')

    update_recipients.uniq.each do |user|
      UserMailer.wiki_content_updated(user, self, User.current).deliver_later
    end
  end

  def create_recipients
    recipients +
      page.wiki.watcher_recipients
  end

  def update_recipients
    recipients +
      page.wiki.watcher_recipients +
      page.watcher_recipients
  end
end
