#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

namespace :ldap_groups do
  desc 'Synchronize groups and their users from the LDAP auth source.' \
       'Will only synchronize for those users already present in the application.'
  task synchronize: :environment do
    ::LdapGroups::SynchronizationService.synchronize!
  end

  desc 'Print all members of groups tied to a synchronized group that are not derived from LDAP'
  task print_unsynced_members: :environment do
    ::LdapGroups::SynchronizedGroup
      .includes(:group)
      .find_each do |sync|

      group = sync.group
      unsynced_logins = User
        .where(id: group.user_ids)
        .where.not(id: sync.users.select(:user_id))
        .pluck(:login)

      if unsynced_logins.any?
        puts "In group #{group}, #{unsynced_logins.count} user(s) exist that are not synced from LDAP:"
        puts unsynced_logins.join(", ")
      end
    end
  end

  namespace :development do
    desc 'Create a development LDAP server from the fixtures LDIF'
    task :ldap_server do
      require 'ladle'
      ldif = ENV.fetch('LDIF_FILE') { Rails.root.join('spec/fixtures/ldap/users.ldif') }
      ldap_server = Ladle::Server.new(quiet: false, port: '12389', domain: 'dc=example,dc=com', ldif:).start

      puts <<~EOS
                #{'        '}
                        LDAP server ready at localhost:12389
                        Users Base dn: ou=people,dc=example,dc=com
                        Admin account: uid=admin,ou=system
                        Admin password: secret
        #{'        '}
                        --------------------------------------------------------
        #{'        '}
                        Attributes
                        Login: uid
                        First name: givenName
                        Last name: sn
                        Email: mail
                        memberOf: (Hard-coded, not virtual)
        #{'        '}
                        --------------------------------------------------------
                #{'          '}
                        Users:
                        uid=aa729,ou=people,dc=example,dc=com (Password: smada)
                        uid=bb459,ou=people,dc=example,dc=com (Password: niwdlab)
                        uid=cc414,ou=people,dc=example,dc=com (Password: retneprac)
        #{'        '}
                        --------------------------------------------------------
        #{'        '}
                        Groups:
                        cn=foo,ou=groups,dc=example,dc=com (Members: aa729)
                        cn=bar,ou=groups,dc=example,dc=com (Members: aa729, bb459, cc414)
      EOS

      puts "Send CTRL+D to stop the server"
      require 'irb'
      binding.irb

      ldap_server.stop
    end
  end
end
