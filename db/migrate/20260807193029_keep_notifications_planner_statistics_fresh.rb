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

# Increase how often autovacuum runs ANALYZE on the high-churn notifications
# table so the query planner keeps accurate row estimates for it. When those
# estimates go stale, the unread-notification bell falls back to a slow
# nested-loop plan instead of a hash semi-join.
class KeepNotificationsPlannerStatisticsFresh < ActiveRecord::Migration[8.0]
  def up
    execute(<<~SQL.squish)
      ALTER TABLE notifications SET (
        autovacuum_analyze_scale_factor = 0.02,
        autovacuum_analyze_threshold = 200
      )
    SQL
  end

  def down
    execute(<<~SQL.squish)
      ALTER TABLE notifications RESET (
        autovacuum_analyze_scale_factor,
        autovacuum_analyze_threshold
      )
    SQL
  end
end
