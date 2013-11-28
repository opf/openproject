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

class Journal::WikiContentJournal < Journal::BaseJournal
  self.table_name = "wiki_content_journals"

  acts_as_activity_provider type: 'wiki_edits',
                            permission: :view_wiki_edits

  def self.extend_event_query(j, ej, query)
    p = Arel::Table.new(:wiki_pages)
    w = Arel::Table.new(:wikis)

    query = query.join(p).on(ej[:page_id].eq(p[:id]))
    query = query.join(w).on(p[:wiki_id].eq(w[:id]))
    [w, query]
  end

  def self.event_query_projection(j, ej)
    p = Arel::Table.new(:wiki_pages)
    w = Arel::Table.new(:wikis)

    [
      w[:project_id].as('project_id'),
      p[:title].as('wiki_title')
    ]
  end

  def self.format_event(event, event_data)
    event.event_title = self.event_title event_data
    event.event_type = 'wiki-page'
    event.event_url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    "#{l(:label_wiki_edit)}: #{event['wiki_title']} (##{event['version']})"
  end

  def self.event_url(event)
    parameters = { project_id: event['project_id'], id: event['journable_id'] }

    Rails.application.routes.url_helpers.project_wiki_path(parameters)
  end
end
