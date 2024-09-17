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

class RemoveProjectFromNotification < ActiveRecord::Migration[7.1]
  def change
    reversible do |direction|
      direction.down do
        execute <<~SQL.squish
          UPDATE notifications
          SET project_id = work_package_journals.project_id
          FROM journals
          JOIN work_package_journals
          ON journals.data_id = work_package_journals.id AND journals.data_type = 'Journal::WorkPackageJournal'
          WHERE notifications.journal_id = journals.id AND notifications.resource_type = 'WorkPackage'
        SQL

        execute <<~SQL.squish
          UPDATE notifications
          SET project_id = forums.project_id
          FROM journals
          JOIN message_journals
          ON journals.data_id = message_journals.id AND journals.data_type = 'Journal::MessageJournal'
          JOIN forums ON message_journals.forum_id = forums.id
          WHERE notifications.journal_id = journals.id AND notifications.resource_type = 'Message'
        SQL

        execute <<~SQL.squish
          UPDATE notifications
          SET project_id = wikis.project_id
          FROM wiki_pages
          JOIN wikis
          ON wiki_pages.wiki_id = wikis.id
          WHERE notifications.resource_id = wiki_pages.id AND notifications.resource_type = 'WikiPage'
        SQL

        execute <<~SQL.squish
          UPDATE notifications
          SET project_id = news_journals.project_id
          FROM journals
          JOIN news_journals
          ON journals.data_id = news_journals.id AND journals.data_type = 'Journal::NewsJournal'
          WHERE notifications.journal_id = journals.id AND notifications.resource_type = 'News'
        SQL

        execute <<~SQL.squish
          UPDATE notifications
          SET project_id = news.project_id
          FROM comments
          JOIN news
          ON comments.commented_id = news.id AND comments.commented_type = 'News'
          WHERE notifications.resource_id = comments.id AND notifications.resource_type = 'Comment'
        SQL
      end
    end

    remove_reference :notifications, :project
  end
end
