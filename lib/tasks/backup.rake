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

require "pathname"

namespace :backup do
  namespace :database do
    desc "Creates a database dump which can be used as a backup."
    task :create, [:path_to_backup] => [:environment] do |_task, args|
      args.with_defaults(path_to_backup: default_db_filename)
      Pathname(args[:path_to_backup]).dirname.mkpath

      include OpenProject::PostgresEnvironment

      pg_dump_call = %W[
        pg_dump
        --clean
        --file=#{args[:path_to_backup]}
        --format=custom
        --no-owner
      ]

      Kernel.system(pg_env, *pg_dump_call)
    end

    desc "Restores a database dump created by the :create task."
    task :restore, [:path_to_backup] => [:environment] do |_task, args|
      raise "You must provide the path to the database dump" unless args[:path_to_backup]
      raise "File '#{args[:path_to_backup]}' is not readable" unless File.readable?(args[:path_to_backup])

      include OpenProject::PostgresEnvironment

      # PGDATABASE is ignored by pg_restore if not specified explicitly
      # https://www.postgresql.org/docs/current/app-pgrestore.html#:~:text=PGDATABASE
      pg_restore_call = %W[
        pg_restore
        --clean
        --no-owner
        --single-transaction
        --dbname=#{pg_env['PGDATABASE']}
        #{args[:path_to_backup]}
      ]

      Kernel.system(pg_env, *pg_restore_call)
    end

    private

    def default_db_filename
      filename = "openproject-#{Rails.env}-db-#{date_string}.backup"
      Rails.root.join("backup", sanitize_filename(filename))
    end

    def date_string
      Time.now.strftime("%Y%m%dT%H%M%S%z") # e.g. "20141020T165335+0200"
    end

    def sanitize_filename(filename)
      filename.gsub(/[^0-9A-Za-z.-]/, "_")
    end
  end

  desc "Allows user-initiated backups right away, skipping the cooldown period after a new token was created."
  task allow_now: :environment do
    date = DateTime.now - OpenProject::Configuration.backup_initial_waiting_period

    Token::Backup.where("created_at > ?", date).each do |token|
      token.update_column :created_at, date
    end
  end
end
