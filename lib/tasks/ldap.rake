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

namespace :ldap do
  def parse_args
    # Rake croaks when using commas in default args without properly escaping
    args = {}
    ARGV.drop(1).each do |arg|
      key, val = arg.split(/\s*=\s*/, 2)
      args[key.to_sym] = val
    end

    args
  end

  desc "Synchronize existing users from the LDAP auth source" \
       'rake ldap:sync name="<LdapAuthSource Name>" users=<login1,login2,...>'
  task sync: :environment do
    args = parse_args
    ldap = LdapAuthSource.find_by!(name: args.fetch(:name))

    logins = args.fetch(:logins, "").split(/\s*,\s*/)
    Ldap::SynchronizeUsersService
      .new(ldap, logins)
      .call
  end

  desc "Synchronize users from the LDAP auth source with an optional filter." \
       "Note: If you omit the filter, ALL users are imported." \
       'rake ldap:import_from_filter name="<LdapAuthSource Name>" filter=<Optional RFC2254 filter string>'
  task import_from_filter: :environment do
    args = parse_args
    ldap = LdapAuthSource.find_by!(name: args.fetch(:name))

    # Parse filter string if available
    filter = Net::LDAP::Filter.from_rfc2254 args.fetch(:filter, "objectClass = *")

    Ldap::ImportUsersFromFilterService
      .new(ldap, filter)
      .call
  end

  desc "Synchronize a list of user logins with the LDAP auth source" \
       'rake ldap:import_from_user_list name=<LdapAuthSource Name>" users=<Path to file with newline separated logins>'
  task import_from_user_list: :environment do
    args = parse_args
    ldap = LdapAuthSource.find_by!(name: args.fetch(:name))
    file = args.fetch(:users)

    puts "--> Reading username file #{file}"
    users = File.read(file).lines(chomp: true)

    Ldap::ImportUsersFromListService
      .new(ldap, users)
      .call
  end

  desc "Register a LDAP auth source for the given LDAP URL and attribute mapping: " \
       'rake ldap:register["url=<URL> name=<Name> onthefly=<true,false>map_{login,firstname,lastname,mail,admin}=attribute,filter_string"]'
  task register: :environment do
    args = parse_args

    url = URI.parse(args[:url])
    unless %w(ldap ldaps).include?(url.scheme)
      raise "Expected #{args[:url]} to be a valid ldap(s) URI."
    end

    source = LdapAuthSource.find_or_initialize_by(name: args[:name])

    unless source.new_record?
      puts "LDAP auth source #{args[:name]} already exists. Updating its attributes instead."
    end

    source.attributes = {
      host: url.host,
      port: url.port,
      tls_mode: url.scheme == "ldaps" ? "start_tls" : "plain_ldap",
      account: url.user,
      account_password: url.password,
      base_dn: url.dn,
      onthefly_register: !!ActiveModel::Type::Boolean.new.cast(args[:onthefly]),
      attr_login: args[:map_login],
      attr_firstname: args[:map_firstname],
      attr_lastname: args[:map_lastname],
      attr_mail: args[:map_mail],
      attr_admin: args[:map_admin]
    }

    source.filter_string = args[:filter_string] if args.key?(:filter_string)

    if source.save
      puts "Saved LDAP auth source #{args[:name]}."
    else
      raise "Failed to save auth source: #{source.errors.full_messages.join("\n")}"
    end
  end
end
