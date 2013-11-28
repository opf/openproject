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

class Journal::ChangesetJournal < Journal::BaseJournal
  self.table_name = "changeset_journals"

  acts_as_activity_provider type: 'changesets',
                            permission: :view_changesets

  def self.extend_event_query(j, ej, query)
    r = Arel::Table.new(:repositories)

    query = query.join(r).on(ej[:repository_id].eq(r[:id]))
    [r, query]
  end

  def self.event_query_projection(j, ej)
    r = Arel::Table.new(:repositories)

    [
      ej[:revision].as('revision'),
      ej[:comments].as('comments'),
      ej[:committed_on].as('committed_on'),
      r[:project_id].as('project_id')
    ]
  end

  def self.format_event(event, event_data)
    event.event_title = self.event_title event_data
    event.event_description = self.split_comment(event_data['comments']).last
    event.event_datetime = DateTime.parse(event_data['committed_on'])
    event.project_id = event_data['project_id'].to_i
    event.event_url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    short_comment = self.split_comment(event['comments']).first

    title = "#{l(:label_revision)} #{event['revision']}"
    title << (short_comment.blank? ? '' : (': ' + short_comment))
  end

  def self.split_comment(comments)
    comments =~ /\A(.+?)\r?\n(.*)\z/m
    short_comments = $1 || comments
    long_comments = $2.to_s.strip

    [short_comments, long_comments]
  end

  def self.event_url(event)
    parameters = { project_id: event['project_id'], rev: event['revision'] }

    Rails.application.routes.url_helpers.revisions_project_repository_path(parameters)
  end
end
