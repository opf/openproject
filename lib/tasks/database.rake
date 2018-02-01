#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace 'db:sessions' do
  desc 'Expire old sessions from the sessions table'
  task :expire, [:days_ago] => [:environment, 'db:load_config'] do |_task, args|
    # sessions expire after 30 days of inactivity by default
    days_ago = Integer(args[:days_ago] || 30)
    expiration_time = Date.today - days_ago.days

    sessions_table = ActiveRecord::SessionStore::Session.table_name
    ActiveRecord::Base.connection.execute "DELETE FROM #{sessions_table} WHERE updated_at < '#{expiration_time}'"
  end
end

namespace 'openproject' do
  namespace 'db' do
    desc 'Ensure database version compatibility'
    task ensure_database_compatibility: ['environment', 'db:load_config'] do

      ##
      # Ensure database server version is compatible
      begin
        OpenProject::Database::check_version!
      rescue OpenProject::Database::InsufficientVersionError => e
        warn <<~EOS
          ---------------------------------------------------
          DATABASE INCOMPATIBILITY ERROR

          #{e.message}

          For more information, visit our upgrading documentation: 
          https://www.openproject.org/operations/upgrading/
          ---------------------------------------------------
        EOS
        Kernel.exit(1)
      rescue ActiveRecord::ActiveRecordError => e
        warn "Failed to perform postgres version check: #{e} - #{e.message}. #{override_msg}"
        raise e
      end
    end
  end
end

Rake::Task["db:migrate"].enhance ["openproject:db:ensure_database_compatibility"]

