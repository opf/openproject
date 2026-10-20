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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class ReorderGoodJobsCronIndex < ActiveRecord::Migration[8.1]
  CURRENT_INDEX = :index_good_jobs_on_cron_key_and_cron_at_cond
  REPLACEMENT_INDEX = :index_good_jobs_on_cron_key_and_cron_at_desc_cond

  disable_ddl_transaction!

  def up
    return if cron_index_has_expected_order?

    add_index :good_jobs, %i[cron_key cron_at],
              name: REPLACEMENT_INDEX,
              order: { cron_at: "DESC NULLS LAST" },
              where: "cron_key IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true
    remove_index :good_jobs, name: CURRENT_INDEX, algorithm: :concurrently, if_exists: true
    rename_index :good_jobs, REPLACEMENT_INDEX, CURRENT_INDEX
  end

  def down
    return if cron_index_definition && !cron_index_has_expected_order?

    add_index :good_jobs, %i[cron_key cron_at],
              name: REPLACEMENT_INDEX,
              where: "cron_key IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true
    remove_index :good_jobs, name: CURRENT_INDEX, algorithm: :concurrently, if_exists: true
    rename_index :good_jobs, REPLACEMENT_INDEX, CURRENT_INDEX
  end

  private

  def cron_index_has_expected_order?
    cron_index_definition&.include?("cron_at DESC NULLS LAST")
  end

  def cron_index_definition
    connection.select_value(<<~SQL.squish)
      SELECT indexdef
      FROM pg_indexes
      WHERE schemaname = ANY (current_schemas(false))
        AND tablename = #{connection.quote('good_jobs')}
        AND indexname = #{connection.quote(CURRENT_INDEX.to_s)}
    SQL
  end
end
