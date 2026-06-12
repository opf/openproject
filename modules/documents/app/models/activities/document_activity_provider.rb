# frozen_string_literal: true

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

class Activities::DocumentActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: "documents",
                        permission: :view_documents

  def event_query_projection
    journals = Journal.arel_table.name
    [
      activity_journal_projection_statement(:title, "document_title"),
      activity_journal_projection_statement(:project_id, "project_id"),
      Arel.sql("MAX(#{journals}.version) OVER (PARTITION BY #{journals}.journable_id) AS journable_max_version")
    ]
  end

  def event_title(event)
    "#{Document.model_name.human}: #{event['document_title']}"
  end

  def event_type(_event)
    "document"
  end

  def event_path(event)
    url_helpers.document_url(versioned_url_params(event))
  end

  def event_url(event)
    url_helpers.document_url(versioned_url_params(event))
  end

  private

  def versioned_url_params(event)
    document_id = event["journable_id"]
    journal_version = event["version"].to_i
    max_version = event["journable_max_version"].to_i

    if journal_version < max_version
      { id: document_id, version: event["event_id"] }
    else
      document_id
    end
  end
end
