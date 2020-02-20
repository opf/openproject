#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require Rails.root.join("db", "migrate", "migration_utils", "migration_squasher").to_s
# This migration aggregates the migrations detailed in MIGRATION_FILES
class ToV710AggregatedReportingMigrations < ActiveRecord::Migration[5.1]
  MIGRATION_FILES = <<-MIGRATIONS
    20110215143061_aggregated_reporting_migrations.rb
    20130612104243_reporting_migrate_serialized_yaml.rb
    20130925090243_cost_reports_migration.rb
  MIGRATIONS

  def up
    Migration::MigrationSquasher.squash(migrations) do
      create_table "cost_queries", id: :integer do |t|
        t.integer  "user_id",                                       :null => false
        t.integer  "project_id"
        t.string   "name",                                          :null => false
        t.boolean  "is_public",                  :default => false, :null => false
        t.datetime "created_on",                                    :null => false
        t.datetime "updated_on",                                    :null => false
        t.string   "serialized", :limit => 2000,                    :null => false
      end
    end
  end

  def down
    drop_table "cost_queries"
  end

  private

  def migrations
    MIGRATION_FILES.split.map do |m|
      m.gsub(/_.*\z/, '')
    end
  end
end
