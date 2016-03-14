#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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

  def event_type(_event, _activity)
    'cost_object'
  end

  def event_title(event, _activity)
    "#{I18n.t(:label_cost_object)} ##{event['journable_id']}: #{event['cost_object_subject']}"
  end

  def event_path(event, _activity)
    url_helpers.cost_object_path(url_helper_parameter(event))
  end

  def event_url(event, _activity)
    url_helpers.cost_object_url(url_helper_parameter(event))
  end

  private

  def url_helper_parameter(event)
    event['journable_id']
  end
end
