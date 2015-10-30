#-- copyright
# OpenProject Documents Plugin
#
# Former OpenProject Core functionality extracted into a plugin.
#
# Copyright (C) 2009-2014 the OpenProject Foundation (OPF)
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

class Activity::DocumentActivityProvider < Activity::BaseActivityProvider
  acts_as_activity_provider type: 'documents',
                            permission: :view_documents

  def event_query_projection(activity)
    [
      activity_journal_projection_statement(:title, 'document_title', activity),
      activity_journal_projection_statement(:project_id, 'project_id', activity)
    ]
  end

  def event_title(event, _activity)
    "#{Document.model_name.human}: #{event['document_title']}"
  end

  def event_type(_event, _activity)
    'document'
  end

  def event_path(event, _activity)
    url_helpers.project_documents_url(url_helper_parameter(event))
  end

  def event_url(event, _activity)
    url_helpers.project_documents_url(url_helper_parameter(event))
  end

  private

  def url_helper_parameter(event)
    event['journable_id']
  end
end
