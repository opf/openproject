#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'tempfile'
require 'fileutils'

namespace :backup do
  namespace :database do
    desc 'Creates a database dump which can be used as a backup.'
    task :create, [:path_to_backup] => [:environment] do |_task, args|
      args.with_defaults(path_to_backup: default_db_filename)
      FileUtils.mkdir_p(Pathname.new(args[:path_to_backup]).dirname)

      config = database_configuration
      case config['adapter']
      when /PostgreSQL/i
        with_pg_config(config) do |config_file|
          pg_dump_call = ['pg_dump',
                          '--clean',
                          "--file=#{args[:path_to_backup]}",
                          '--format=custom',
                          '--no-owner']
          pg_dump_call << "--host=#{config['host']}" if config['host']
          pg_dump_call << "--port=#{config['port']}" if config['port']
          user = config.values_at('user', 'username').compact.first
          pg_dump_call << "--username=#{user}" if user
          pg_dump_call << "#{config['database']}"

          if config['password']
            Kernel.system({ 'PGPASSFILE' => config_file }, *pg_dump_call)
          else
            Kernel.system(*pg_dump_call)
          end
        end
      when /MySQL2/i
        with_mysql_config(config) do |config_file|
          Kernel.system 'mysqldump',
                        "--defaults-file=#{config_file}",
                        '--single-transaction',
                        '--add-drop-table',
                        '--add-locks',
                        "--result-file=#{args[:path_to_backup]}",
                        "#{config['database']}"
        end
      else
        raise "Database '#{config['adapter']}' not supported."
      end
    end

    desc 'Restores a database dump created by the :create task.'
    task :restore, [:path_to_backup] => [:environment] do |_task, args|
      raise 'You must provide the path to the database dump' unless args[:path_to_backup]
      raise "File '#{args[:path_to_backup]}' is not readable" unless File.readable?(args[:path_to_backup])

      config = database_configuration
      case config['adapter']
      when /PostgreSQL/i
        with_pg_config(config) do |config_file|
          pg_restore_call = ['pg_restore',
                             '--clean',
                             '--no-owner',
                             '--single-transaction',
                             "--dbname=#{config['database']}"]
          pg_restore_call << "--host=#{config['host']}" if config['host']
          pg_restore_call << "--port=#{config['port']}" if config['port']
          user = config.values_at('user', 'username').compact.first
          pg_restore_call << "--username=#{user}" if user
          pg_restore_call << "#{args[:path_to_backup]}"

          if config['password']
            Kernel.system({ 'PGPASSFILE' => config_file }, *pg_restore_call)
          else
            Kernel.system(*pg_restore_call)
          end
        end
      when /MySQL2/i
        with_mysql_config(config) do |config_file|
          Kernel.system "mysql --defaults-file=\"#{config_file}\" \"#{config['database']}\" < \"#{args[:path_to_backup]}\""
        end
      else
        raise "Database '#{config['adapter']}' not supported."
      end
    end

    private

    def database_configuration
      ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
    end

    def with_pg_config(config, &blk)
      file = Tempfile.new('op_pg_config')
      file.write "*:*:*:*:#{config['password']}"
      file.close
      blk.yield file.path
      file.unlink
    end

    def with_mysql_config(config, &blk)
      file = Tempfile.new('op_mysql_config')
      file.write sql_dump_tempfile(config)
      file.close
      blk.yield file.path
      file.unlink
    end

    def sql_dump_tempfile(config)
      t =  "[client]\n"
      t << "password=\"#{config['password']}\"\n"
      t << "user=\"#{config.values_at('user', 'username').compact.first}\"\n"
      t << "host=\"#{config['host'] || '127.0.0.1'}\"\n"
      t << "port=\"#{config['port']}\"\n" if config['port']
      t << "ssl-key=\"#{config['sslkey']}\"\n" if config['sslkey']
      t << "ssl-cert=\"#{config['sslcert']}\"\n" if config['sslcert']
      t << "ssl-ca=\"#{config['sslca']}\"\n" if config['sslca']
      t
    end

    def default_db_filename
      filename = "openproject-#{Rails.env}-db-#{date_string}"
      case database_configuration['adapter']
      when /PostgreSQL/i
        filename << '.backup'
      else
        filename << '.sql'
      end
      Rails.root.join('backup', sanitize_filename(filename))
    end

    def date_string
      Time.now.strftime('%Y%m%dT%H%M%S%z') # e.g. "20141020T165335+0200"
    end

    def sanitize_filename(filename)
      filename.gsub(/[^0-9A-Za-z.-]/, '_')
    end
  end
end
