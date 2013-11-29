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

class Journal::CostObjectJournal < Journal::BaseJournal
  self.table_name = "cost_object_journals"

  acts_as_activity_provider type: 'cost_objects',
                            permission: :view_cost_objects

  def self.extend_event_query(j, ej, query)
    [ej, query]
  end

  def self.event_query_projection(j, ej)
    [
      ej[:subject].as('cost_object_subject'),
      ej[:project_id].as('project_id')
    ]
  end

  def self.format_event(event, event_data)
    event.event_title = self.event_title event_data
    event.event_path = self.event_path event_data
    event.event_url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    "#{l(:label_cost_object)} ##{event['journable_id']}: #{event['cost_object_subject']}"
  end

  def self.event_path(event)
    Rails.application.routes.url_helpers.cost_object_path(self.url_helper_parameter(event))
  end

  def self.event_url(event)
    Rails.application.routes.url_helpers.cost_object_url(self.url_helper_parameter(event),
                                                         host: ::Setting.host_name)
  end

  def self.url_helper_parameter(event)
    event['journable_id']
  end
end
