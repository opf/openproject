# --copyright
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
# ++

module API::V3::Notifications
  module PropertyFactory
    extend ::API::V3::Utilities::PathHelper

    PROPERTY_FOR_REASON = {
      date_alert_start_date: "start_date",
      date_alert_due_date: "due_date",
      date_alert_date: "date"
    }.freeze

    DATE_ALERT_REASONS = %w(date_alert_start_date date_alert_due_date).freeze

    module_function

    # Fetch the collection of details for a notification
    def details_for(notification)
      concrete_factory_for(notification)
        .for(notification)
    end

    # Fetch the collection of schemas for the provided notifications.
    def schemas_for(notifications)
      detail_properties = notifications.reduce(Set.new) do |properties, notification|
        next properties unless PROPERTY_FOR_REASON.has_key?(notification.reason.to_sym)

        properties << if notification.resource.is_milestone?
                        PROPERTY_FOR_REASON[:date_alert_date]
                      else
                        PROPERTY_FOR_REASON[notification.reason.to_sym]
                      end
      end

      ::API::V3::Values::Schemas::ValueSchemaFactory.all_for(detail_properties)
    end

    # Returns the outward facing notification group attributes
    def groups_for(values)
      group_values = values.except(*DATE_ALERT_REASONS)
      date_alert_values = values.slice(*DATE_ALERT_REASONS).values.sum
      group_values["dateAlert"] = date_alert_values if date_alert_values > 0
      group_values
    end

    # Returns the outward facing reason e.g. `dateAlert` as opposed to `date_alert_start_date`.
    def reason_for(notification)
      reason = notification.reason
      case reason
      when *DATE_ALERT_REASONS
        "dateAlert"
      else
        reason
      end
    end

    def concrete_factory_for(notification)
      property_name = notification.reason

      if notification.reason.in?(DATE_ALERT_REASONS) && notification.resource&.is_milestone?
        property_name = "date_alert_date"
      end

      @concrete_factory_for ||= Hash.new do |h, property_key|
        h[property_key] = if property_key == "shared"
                            # for some reasons
                            # API::V3::Notifications::PropertyFactory.const_defined?(property_key.camelcase)
                            # returns true for shared only to fail on the constantize later on.
                            API::V3::Notifications::PropertyFactory::Default
                          elsif API::V3::Notifications::PropertyFactory.const_defined?(property_key.camelcase)
                            "API::V3::Notifications::PropertyFactory::#{property_key.camelcase}".constantize
                          else
                            API::V3::Notifications::PropertyFactory::Default
                          end
      end

      @concrete_factory_for[property_name]
    end
  end
end
