#-- encoding: UTF-8
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

namespace :ldap_groups do
  desc 'Synchronize groups and their users from the LDAP auth source.' \
       'Will only synchronize for those users already present in the application.'
  task synchronize: :environment do

    begin
      LdapAuthSource.find_each do |ldap|
        puts ("-" * 20)
        puts "Synchronizing for ldap auth source #{ldap.name}"
        OpenProject::LdapGroups::Synchronization.new(ldap)
      end
    rescue =>  e
      msg = "Failed to run LDAP group synchronization. #{e.class.name}: #{e.message}"
      Rails.logger.error msg
      warn msg
    end
  end
end

# Ensure core cron task is loaded
load 'lib/tasks/cron.rake'
Rake::Task["openproject:cron:hourly"].enhance do
  Rake::Task["ldap_groups:synchronize"].invoke
end
