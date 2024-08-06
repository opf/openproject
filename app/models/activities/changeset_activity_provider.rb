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

class Activities::ChangesetActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: "changesets",
                        permission: :view_changesets

  def extend_event_query(query)
    query.join(repositories_table).on(activity_journals_table[:repository_id].eq(repositories_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:revision, "revision"),
      activity_journal_projection_statement(:comments, "comments"),
      activity_journal_projection_statement(:committed_on, "committed_on"),
      projection_statement(repositories_table, :project_id, "project_id"),
      projection_statement(repositories_table, :type, "repository_type")
    ]
  end

  def projects_reference_table
    repositories_table
  end

  ##
  # Override this method if not the journal created_at datetime, but another column
  # value is the actual relevant time event. (e..g., commit date)
  def filter_for_event_datetime(query, from, to)
    if from
      query = query.where(activity_journals_table[:committed_on].gteq(from))
    end

    if to
      query = query.where(activity_journals_table[:committed_on].lteq(to))
    end

    query
  end

  protected

  def event_type(_event)
    "changeset"
  end

  def event_title(event)
    revision = format_revision(event)

    short_comment = split_comment(event["comments"]).first

    title = "#{I18n.t(:label_revision)} #{revision}"
    title << (short_comment.blank? ? "" : (": " + short_comment))
  end

  def event_description(event)
    split_comment(event["comments"]).last
  end

  def event_datetime(event)
    committed_on = event["committed_on"]
    committed_on.is_a?(String) ? DateTime.parse(committed_on) : committed_on
  end

  def event_path(event)
    url_helpers.revisions_project_repository_path(url_helper_parameter(event))
  end

  def event_url(event)
    url_helpers.revisions_project_repository_url(url_helper_parameter(event))
  end

  private

  def repositories_table
    @repositories_table ||= Repository.arel_table
  end

  def format_revision(event)
    repository_class = event["repository_type"].constantize

    repository_class.respond_to?(:format_revision) ? repository_class.format_revision(event["revision"]) : event["revision"]
  end

  def split_comment(comments)
    comments =~ /\A(.+?)\r?\n(.*)\z/m
    short_comments = $1 || comments
    long_comments = $2.to_s.strip

    [short_comments, long_comments]
  end

  def url_helper_parameter(event)
    { project_id: event["project_id"], rev: event["revision"] }
  end
end
