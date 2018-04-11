#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
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

require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
# This migration aggregates the migrations detailed in MIGRATION_FILES
class ToV710AggregatedMyProjectPageMigrations < ActiveRecord::Migration[5.1]

  MIGRATION_FILES = <<-MIGRATIONS
    20120605121861_aggregated_my_project_page_migrations.rb
    20130903172842_my_project_page_migrate_serialized_yaml.rb
    20130904181242_rename_blocks_keys.rb
  MIGRATIONS

  def up
    Migration::MigrationSquasher.squash(migrations) do
      create_table :my_projects_overviews, id: :integer do |t|
        t.integer "project_id", default: 0, null: false
        t.text "left", null: false
        t.text "right", null: false
        t.text "top", null: false
        t.text "hidden", null: false
        t.datetime "created_on", null: false
      end
    end
  end

  def down
    drop_table :my_projects_overviews
  end

  private

  def migrations
    MIGRATION_FILES.split.map do |m|
      m.gsub(/_.*\z/, '')
    end
  end
end
