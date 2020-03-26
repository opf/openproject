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

class Activities::WikiContentActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: 'wiki_edits',
                        permission: :view_wiki_edits

  def extend_event_query(query)
    query.join(wiki_pages_table).on(activity_journals_table[:page_id].eq(wiki_pages_table[:id]))
    query.join(wikis_table).on(wiki_pages_table[:wiki_id].eq(wikis_table[:id]))
  end

  def event_query_projection
    [
      projection_statement(wikis_table, :project_id, 'project_id'),
      projection_statement(wiki_pages_table, :title, 'wiki_title')
    ]
  end

  def projects_reference_table
    wikis_table
  end

  protected

  def event_title(event)
    "#{l(:label_wiki_edit)}: #{event['wiki_title']} (##{event['version']})"
  end

  def event_type(_event)
    'wiki-page'
  end

  def event_path(event)
    url_helpers.project_wiki_path(*url_helper_parameter(event))
  end

  def event_url(event)
    url_helpers.project_wiki_url(*url_helper_parameter(event))
  end

  private

  def wiki_pages_table
    @wiki_pages_table ||= WikiPage.arel_table
  end

  def wikis_table
    @wikis_table ||= Wiki.arel_table
  end

  def url_helper_parameter(event)
    [event['project_id'], event['wiki_title'], { version: event['version'] }]
  end
end
