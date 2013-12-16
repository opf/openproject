#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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

  def event_title(event, activity)
    "#{Document.model_name.human}: #{event['document_title']}"
  end

  def event_path(event, activity)
    Rails.application.routes.url_helpers.project_document_path(url_helper_parameter(event))
  end

  def event_url(event, activity)
    Rails.application.routes.url_helpers.project_document_url(url_helper_parameter(event),
                                                              host: ::Setting.host_name)
  end

  private

  def url_helper_parameter(event)
    event['journable_id']
  end
end
