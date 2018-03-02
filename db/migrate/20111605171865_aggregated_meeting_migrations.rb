#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require Rails.root.join('db', 'migrate', 'migration_utils', 'migration_squasher').to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedMeetingMigrations < ActiveRecord::Migration[5.0]
  MIGRATION_FILES = <<-MIGRATIONS
    20110106210555_create_meetings.rb
    20110106221214_create_meeting_contents.rb
    20110106221946_create_meeting_content_versions.rb
    20110108230721_create_meeting_participants.rb
    20110224180804_add_lock_to_meeting_content.rb
    20110819162852_create_initial_meeting_journals.rb
    20111605171815_merge_meeting_content_versions_with_journals.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = 'redmine_meeting'

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      create_table 'meeting_contents' do |t|
        t.string 'type'
        t.integer 'meeting_id'
        t.integer 'author_id'
        t.text 'text'
        t.integer 'lock_version'
        t.datetime 'created_at',                      null: false
        t.datetime 'updated_at',                      null: false
        t.boolean 'locked',       default: false
      end

      create_table 'meeting_participants' do |t|
        t.integer 'user_id'
        t.integer 'meeting_id'
        t.integer 'meeting_role_id'
        t.string 'email'
        t.string 'name'
        t.boolean 'invited'
        t.boolean 'attended'
        t.datetime 'created_at',      null: false
        t.datetime 'updated_at',      null: false
      end

      create_table 'meetings' do |t|
        t.string 'title'
        t.integer 'author_id'
        t.integer 'project_id'
        t.string 'location'
        t.datetime 'start_time'
        t.float 'duration'
        t.datetime 'created_at', null: false
        t.datetime 'updated_at', null: false
      end
    end
  end

  def down
    drop_table 'meeting_contents'
    drop_table 'meeting_participants'
    drop_table 'meetings'
  end
end
