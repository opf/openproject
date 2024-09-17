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

class Notifications::CreateDateAlertsNotificationsJob::AlertableWorkPackages
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def alertable_for_start
    alertable_for("start_alert")
  end

  def alertable_for_due
    alertable_for("due_alert")
  end

  private

  def alertable_for(alert)
    find_alertables
      .filter_map { |row| row["id"] if row[alert] }
      .then { |ids| WorkPackage.where(id: ids) }
  end

  def find_alertables
    @find_alertables ||= ActiveRecord::Base.connection.execute(query).to_a
  end

  def query
    today = Arel::Nodes::build_quoted(Date.current).to_sql

    alertables = alertable_work_packages
      .select(:id,
              :project_id,
              "work_packages.start_date - #{today} AS start_delta",
              "work_packages.due_date - #{today} AS due_delta",
              "#{today} - work_packages.due_date AS overdue_delta")
      .where("work_packages.start_date IN #{alertable_dates} " \
             "OR work_packages.due_date IN #{alertable_dates} " \
             "OR work_packages.due_date < #{today}")

    <<~SQL.squish
      WITH
      alertable_work_packages (id, project_id, start_delta, due_delta, overdue_delta) AS (
        #{alertables.to_sql}
      ),
      project_ids AS (
        SELECT distinct project_id
        FROM alertable_work_packages
      ),
      project_notification_settings (project_id, start_delta, due_delta, overdue_step) AS (
        SELECT DISTINCT ON (project_ids.project_id)
          project_ids.project_id,
          notification_settings.start_date,
          notification_settings.due_date,
          notification_settings.overdue
        FROM project_ids
          LEFT OUTER JOIN notification_settings ON (
            notification_settings.project_id = project_ids.project_id
            OR notification_settings.project_id IS NULL
          )
        WHERE notification_settings.user_id = #{user.id}
        ORDER BY project_ids.project_id, notification_settings.project_id NULLS LAST
      ),
      notifiable_work_packages (id, start_alert, due_alert) AS (
        SELECT
            alertable_work_packages.id,
            pns.start_delta = alertable_work_packages.start_delta AS start_alert,
            (
              (pns.due_delta = alertable_work_packages.due_delta)
              OR (alertable_work_packages.overdue_delta > 0)
            ) AS due_alert
        FROM alertable_work_packages
          LEFT OUTER JOIN project_notification_settings AS pns USING (project_id)
        WHERE pns.start_delta = alertable_work_packages.start_delta
          OR pns.due_delta = alertable_work_packages.due_delta
          OR (
            (alertable_work_packages.overdue_delta > 0)
            AND (MOD(alertable_work_packages.overdue_delta - 1, pns.overdue_step) = 0)
          )
      )
      SELECT id, start_alert, due_alert
      FROM notifiable_work_packages
    SQL
  end

  def alertable_work_packages
    work_packages = WorkPackage
      .with_status_open
      .involving_user(user)

    # `work_packages.to_sql` was producing SQL with weird select clauses that could
    # not be used in a CTE, while doing `work_packages.pluck(:something)` was producing
    # nice formatted sql. Reading `#pluck` source code revealed the existence
    # of `#join_dependency` and how to use it to have a nicely formatted sql
    # query.
    join_dependency = work_packages.construct_join_dependency([:status], Arel::Nodes::OuterJoin)
    work_packages.joins(join_dependency)
  end

  def alertable_dates
    dates = UserPreferences::ParamsContract::DATE_ALERT_DURATIONS
              .compact
              .map { |offset| Arel::Nodes::build_quoted(Date.current + offset.days) }

    Arel::Nodes::Grouping.new(dates).to_sql
  end
end
