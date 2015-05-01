#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WikiContentObserver < ActiveRecord::Observer
  def after_create(wiki_content)
    if Setting.notified_events.include?('wiki_content_added')
      recipients = wiki_content.recipients + wiki_content.page.wiki.watcher_recipients
      users = User.find_all_by_mails(recipients.uniq)
      users.each do |user|
        UserMailer.wiki_content_added(user, wiki_content, User.current).deliver
      end
    end
  end

  def after_update(wiki_content)
    if wiki_content.text_changed? && Setting.notified_events.include?('wiki_content_updated')
      recipients = wiki_content.recipients + wiki_content.page.wiki.watcher_recipients + wiki_content.page.watcher_recipients
      users = User.find_all_by_mails(recipients.uniq)
      users.each do |user|
        UserMailer.wiki_content_updated(user, wiki_content, User.current).deliver
      end
    end
  end
end
