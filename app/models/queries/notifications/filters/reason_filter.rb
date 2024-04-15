#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Queries::Notifications::Filters::ReasonFilter < Queries::Notifications::Filters::NotificationFilter
  REASONS = Notification
              .reasons
              .except(:date_alert_start_date, :date_alert_due_date)
              .merge(dateAlert: [Notification::REASONS[:date_alert_start_date],
                                 Notification::REASONS[:date_alert_due_date]])
              .freeze

  def allowed_values
    reasons = REASONS.keys
    reasons = reasons.without("dateAlert") unless EnterpriseToken.allows_to?(:date_alerts)
    reasons.map { |reason| [reason, reason] }
  end

  def type
    :list
  end

  def where
    id_values = values.flat_map { |value| REASONS[value] }
    operator_strategy.sql_for_field(id_values, self.class.model.table_name, :reason)
  end
end
