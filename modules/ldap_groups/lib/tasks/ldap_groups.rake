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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

namespace :ldap_groups do
  desc "Synchronize groups and their users from the LDAP auth source." \
       "Will only synchronize for those users already present in the application."
  task synchronize: :environment do
    LdapGroups::SynchronizationService.synchronize!
  end

  desc "Print all members of groups tied to a synchronized group that are not derived from LDAP"
  task print_unsynced_members: :environment do
    LdapGroups::SynchronizedGroup
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
    desc "Create a development LDAP server from the fixtures LDIF"
    task ldap_server: :environment do
      require "ladle"
      ldif = ENV.fetch("LDIF_FILE") { Rails.root.join("spec/fixtures/ldap/users.ldif") }
      ldap_server = Ladle::Server.new(quiet: false, port: "12389", domain: "dc=example,dc=com", ldif:).start

      puts "Creating a connection called ladle"
      source = LdapAuthSource.find_or_initialize_by(name: "ladle local development")

      source.attributes = {
        host: "localhost",
        port: "12389",
        tls_mode: "plain_ldap",
        account: "uid=admin,ou=system",
        account_password: "secret",
        base_dn: "dc=example,dc=com",
        onthefly_register: true,
        attr_login: "uid",
        attr_firstname: "givenName",
        attr_lastname: "sn",
        attr_mail: "mail",
        attr_admin: "isAdmin"
      }

      source.save!

      filter = LdapGroups::SynchronizedFilter.find_or_initialize_by(ldap_auth_source: source, name: "All groups")
      filter.group_name_attribute = "dn"
      filter.sync_users = true
      filter.filter_string = "(cn=*)"
      filter.base_dn = "ou=groups,dc=example,dc=com"

      filter.save!

      puts "Set up group synchronization filter 'All groups' and synchronizing LDAP groups..."
      LdapGroups::SynchronizationJob.perform_now
      puts "  → Synchronized #{LdapGroups::SynchronizedGroup.count} group(s)."

      # The fixture also ships a nested organizational unit tree below ou=org, which is mirrored
      # into departments so the development server demonstrates department synchronization too.
      tree = LdapDepartments::SynchronizedTree.find_or_initialize_by(ldap_auth_source: source, name: "Organization")
      tree.base_dn = "ou=org,dc=example,dc=com"
      tree.structure_filter_string = "(objectClass=organizationalUnit)"
      tree.ou_name_attribute = "ou"
      tree.sync_users = true
      tree.save!

      puts "Set up department synchronization 'Organization' and synchronizing organizational units..."
      LdapDepartments::SynchronizationService.synchronize!
      puts "  → Synchronized #{LdapDepartments::SynchronizedDepartment.count} department(s)."

      puts <<~INFO
        LDAP server ready at localhost:12389

        Synchronizations configured:
          - Group synchronization via filter "All groups" (base ou=groups)
          - Department synchronization via tree "Organization" (base ou=org)

        --------------------------------------------------------

        Connection details

        Host: localhost
        Port: 12389
        No encryption

        --------------------------------------------------------

        System account

        Account: uid=admin,ou=system
        Password: secret

        --------------------------------------------------------

        LDAP details

        Base DN: ou=people,dc=example,dc=com

        --------------------------------------------------------

        Attribute mapping

        Login: uid
        First name: givenName
        Last name: sn
        Email: mail
        Admin: isAdmin
        memberOf: (Hard-coded, not virtual)

        --------------------------------------------------------

        Users

        uid=aa729,ou=people,dc=example,dc=com (Password: smada)
        uid=bb459,ou=people,dc=example,dc=com (Password: niwdlab)
        uid=cc414,ou=people,dc=example,dc=com (Password: retneprac)
        uid=bölle,ou=people,dc=example,dc=com (Password: bólle)

        Department members (below ou=org):

        uid=jdoe,ou=Frontend,ou=Development,ou=IT,ou=org,dc=example,dc=com (Password: john)
        uid=bsmith,ou=Backend,ou=Development,ou=IT,ou=org,dc=example,dc=com (Password: bob)
        uid=hwest,ou=Recruiting,ou=Human Resources,ou=org,dc=example,dc=com (Password: helen)

        --------------------------------------------------------

        Groups

        cn=foo,ou=groups,dc=example,dc=com (Members: aa729)
        cn=bar,ou=groups,dc=example,dc=com (Members: aa729, bb459, cc414)

        --------------------------------------------------------

        Organizational units / Departments (synced from ou=org,dc=example,dc=com)

        IT
          Development
            Frontend          (member: jdoe)
            Backend           (member: bsmith)
          Support
        Human Resources
          Recruiting          (member: hwest)
          Support

        Manage under Administration > Authentication > LDAP department synchronization.
        Departments appear under Administration > Departments.

      INFO

      puts "Send CTRL+D to stop the server"
      require "irb"
      binding.irb # rubocop:disable Lint/Debugger

      ldap_server.stop
    end

    desc "Create a development LDAP server using groupOfUniqueNames/uniqueMember (forward lookup, no memberOf on users)"
    task ldap_server_forward: :environment do
      require "ladle"
      ldif = ENV.fetch("LDIF_FILE") { Rails.root.join("spec/fixtures/ldap/users_unique_member.ldif") }
      ldap_server = Ladle::Server.new(quiet: false, port: "12389", domain: "dc=example,dc=com", ldif:).start

      source = LdapAuthSource.find_or_initialize_by(name: "ladle forward lookup")

      source.attributes = {
        host: "localhost",
        port: "12389",
        tls_mode: "plain_ldap",
        account: "uid=admin,ou=system",
        account_password: "secret",
        base_dn: "dc=example,dc=com",
        onthefly_register: true,
        attr_login: "uid",
        attr_firstname: "givenName",
        attr_lastname: "sn",
        attr_mail: "mail"
      }

      source.save!

      filter = LdapGroups::SynchronizedFilter.find_or_initialize_by(ldap_auth_source: source, name: "All groups")
      filter.group_name_attribute = "dn"
      filter.sync_users = true
      filter.filter_string = "(cn=*)"
      filter.base_dn = "ou=groups,dc=example,dc=com"
      filter.member_lookup_attribute = "uniqueMember"

      filter.save!

      LdapGroups::SynchronizationJob.perform_now

      puts <<~INFO
        LDAP server ready at localhost:12389 (forward lookup mode)

        member_lookup_attribute: uniqueMember
        Groups use groupOfUniqueNames — users have NO memberOf attribute.

        --------------------------------------------------------

        Users

        uid=aa729,ou=people,dc=example,dc=com (Password: smada)    → engineering, cross-functional
        uid=bb459,ou=people,dc=example,dc=com (Password: niwdlab)  → engineering
        uid=cc414,ou=people,dc=example,dc=com (Password: retneprac) → management, cross-functional

        --------------------------------------------------------

        Groups

        cn=engineering,ou=groups,dc=example,dc=com    (Members: aa729, bb459)
        cn=management,ou=groups,dc=example,dc=com     (Members: cc414)
        cn=cross-functional,ou=groups,dc=example,dc=com (Members: aa729, cc414)

      INFO

      puts "Send CTRL+D to stop the server"
      require "irb"
      binding.irb # rubocop:disable Lint/Debugger

      ldap_server.stop
    end
  end
end
