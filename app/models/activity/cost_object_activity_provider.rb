#-- encoding: UTF-8
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

class Activity::CostObjectActivityProvider < Activity::BaseActivityProvider
  acts_as_activity_provider type: 'cost_objects',
                            permission: :view_cost_objects

  def event_query_projection(activity)
    [
      activity_journal_projection_statement(:subject, 'cost_object_subject', activity),
      activity_journal_projection_statement(:project_id, 'project_id', activity)
    ]
  end

  def event_title(event, activity)
    "#{l(:label_cost_object)} ##{event['journable_id']}: #{event['cost_object_subject']}"
  end

  def event_path(event, activity)
    Rails.application.routes.url_helpers.cost_object_path(url_helper_parameter(event))
  end

  def event_url(event, activity)
    Rails.application.routes.url_helpers.cost_object_url(url_helper_parameter(event),
                                                         host: ::Setting.host_name)
  end

  private

  def url_helper_parameter(event)
    event['journable_id']
  end
end
