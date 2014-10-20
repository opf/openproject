#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
    desc "Creates a database dump which can be used as a backup.\n"
    task :create, [:path_to_backup] => [:environment] do |task, args|
      args.with_defaults(:path_to_backup => default_db_filename)
      FileUtils.mkdir_p(Pathname.new(args[:path_to_backup]).dirname)

      conn = ActiveRecord::Base.connection
      case conn.adapter_name
      when /PotsgreSQL/i
        raise "Database '#{conn.adapter_name}' not supported."
      when /MySQL2/i
        with_mysql_config do |config_file|
          system "mysqldump --defaults-file=\"#{config_file}\" --single-transaction \"#{database_name}\" | gzip > \"#{args[:path_to_backup]}\""
        end
      else
        raise "Database '#{conn.adapter_name}' not supported."
      end
    end

    desc "Restores a database dump created by the :create task.\n"
    task :restore, [:path_to_backup] => [:environment] do |task, args|
      raise "You must provide the path to the database dump" unless args[:path_to_backup]
      raise "File '#{args[:path_to_backup]}' is not readable" unless File.readable?(args[:path_to_backup])

      conn = ActiveRecord::Base.connection
      case conn.adapter_name
      when /PotsgreSQL/i
        raise "Database '#{conn.adapter_name}' not supported."
      when /MySQL2/i
        with_mysql_config do |config_file|
          system "gzip -d < \"#{args[:path_to_backup]}\" | mysql --defaults-file=\"#{config_file}\" \"#{database_name}\""
        end
      else
        raise "Database '#{conn.adapter_name}' not supported."
      end
    end

    private
    def with_mysql_config(&blk)
        file = Tempfile.new('op_mysql_config')
        file.write sql_dump_tempfile
        file.close
        blk.yield file.path
        file.unlink
    end

    def database_name
      ActiveRecord::Base.configurations[Rails.env]['database']
    end

    def sql_dump_tempfile
      config = ActiveRecord::Base.configurations[Rails.env]
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
      Rails.root.join('backup', "openproject-#{sanitize_filename(Rails.env.to_s)}-db-#{date_string}.sql.zip")
    end

    def date_string
      time = Time.now.strftime('%Y%m%dT%H%M%S%z') # e.g. "20141020T165335+0200"
      sanitize_filename(time)
    end

    def sanitize_filename(filename)
      filename.gsub(/[^0-9A-Za-z.-]/, '_')
    end
  end
end
