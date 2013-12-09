#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

class Journal::NewsJournal < Journal::BaseJournal
  self.table_name = "news_journals"

  acts_as_activity_provider type: 'news',
                            permission: :view_news

  def self.extend_event_query(journals_table, activity_journals_table, query)
    [activity_journals_table, query]
  end

  def self.event_query_projection(journals_table, activity_journals_table)
    [
      activity_journals_table[:title].as('title'),
      activity_journals_table[:project_id].as('project_id')
    ]
  end

  def self.format_event(event, event_data)
    event.event_title = event_data['title']
    event.event_path = self.event_path event_data
    event.event_url = self.event_url event_data

    event
  end

  private 

  def self.event_path(event)
    Rails.application.routes.url_helpers.news_path(self.url_helper_parameter(event))
  end

  def self.event_url(event)
    Rails.application.routes.url_helpers.news_url(self.url_helper_parameter(event),
                                                  host: ::Setting.host_name)
  end

  def self.url_helper_parameter(event)
    event['journable_id']
  end
end
