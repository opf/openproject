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

namespace :ldap_departments do
  desc "Synchronize departments and their members from the configured LDAP organizational units."
  task synchronize: :environment do
    LdapDepartments::SynchronizationService.synchronize!
  end

  namespace :development do
    desc "Create a development LDAP server with a nested OU tree synced into departments"
    task ldap_server: :environment do
      require "ladle"
      ldif = ENV.fetch("LDIF_FILE") { Rails.root.join("spec/fixtures/ldap/users.ldif") }
      ldap_server = Ladle::Server.new(quiet: false, port: "12389", domain: "dc=example,dc=com", ldif:).start

      source = LdapAuthSource.find_or_initialize_by(name: "ladle departments")
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

      tree = LdapDepartments::SynchronizedTree.find_or_initialize_by(ldap_auth_source: source, name: "Organization")
      tree.base_dn = "ou=org,dc=example,dc=com"
      tree.structure_filter_string = "(objectClass=organizationalUnit)"
      tree.ou_name_attribute = "ou"
      tree.sync_users = true
      tree.save!

      # Run the service directly rather than the job so the dev server syncs even without an
      # Enterprise token present.
      LdapDepartments::SynchronizationService.synchronize!

      puts <<~INFO
        LDAP server ready at localhost:12389

        Synchronized the organizational unit tree below ou=org,dc=example,dc=com into departments:

          IT
            Development
              Frontend          (member: jdoe)
              Backend           (member: bsmith)
            Support
          Human Resources
            Recruiting          (member: hwest)
            Support

        Manage the synchronization under Administration > Authentication > LDAP department synchronization.
        Departments appear under Administration > Departments.

        --------------------------------------------------------

        System account

        Account: uid=admin,ou=system
        Password: secret
      INFO

      puts "Send CTRL+D to stop the server"
      require "irb"
      binding.irb # rubocop:disable Lint/Debugger

      ldap_server.stop
    end
  end
end
