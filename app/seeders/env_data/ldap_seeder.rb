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
module EnvData
  class LdapSeeder < Seeder
    KNOWN_CONNECTION_KEYS = %w[
      host port security tls_verify tls_certificate sync_users
      filter basedn binduser bindpassword
      login_mapping firstname_mapping lastname_mapping mail_mapping admin_mapping
      groupfilter
    ].freeze

    KNOWN_FILTER_KEYS = %w[base filter sync_users group_attribute].freeze

    def seed_data!
      print_status "    ↳ Creating LDAP connection" do
        Setting.seed_ldap.each do |name, options|
          validate_options!(name, options)

          ldap = LdapAuthSource.find_or_initialize_by(name:)

          print_ldap_status(ldap)
          upsert_settings(ldap, options)
          update_filters(ldap, options["groupfilter"])
        end
      end

      print_status "    ↳ Synchronizing LDAP connections" do
        LdapGroups::SynchronizationJob.perform_now
      end
    end

    def applicable?
      Setting.seed_ldap.present?
    end

    private

    def validate_options!(name, options)
      check_unknown_keys!(options, KNOWN_CONNECTION_KEYS,
                          scope: "LDAP connection '#{name}'")

      filters = options["groupfilter"]
      return if filters.blank?

      filters.each do |filter_name, filter_options|
        check_unknown_keys!(filter_options, KNOWN_FILTER_KEYS,
                            scope: "LDAP group filter '#{filter_name}' (connection '#{name}')")
      end
    end

    def check_unknown_keys!(options, known_keys, scope:)
      unknown = options.keys - known_keys
      return if unknown.empty?

      raise <<~MSG.strip
        #{scope}: unknown configuration key(s): #{unknown.map { |k| env_form(k) }.join(', ')}.
        Accepted keys: #{known_keys.map { |k| env_form(k) }.join(', ')}.
        Note: in environment variable names, single underscores split path segments and double underscores encode a literal underscore (e.g. LOGIN__MAPPING, not LOGIN_MAPPING).
      MSG
    end

    def env_form(key)
      key.gsub("_", "__").upcase
    end

    # rubocop:disable Metrics/AbcSize
    def upsert_settings(ldap, options)
      ldap.host = options["host"]
      ldap.port = options["port"]

      ldap.tls_mode = options["security"]
      ldap.verify_peer = ActiveRecord::Type::Boolean.new.deserialize options.fetch("tls_verify", true)
      ldap.onthefly_register = ActiveRecord::Type::Boolean.new.deserialize options.fetch("sync_users", false)
      ldap.tls_certificate_string = options["tls_certificate"].presence

      ldap.filter_string = options["filter"].presence
      ldap.base_dn = options["basedn"]
      ldap.account = options["binduser"]
      ldap.account_password = options["bindpassword"]

      ldap.attr_login = options["login_mapping"].presence
      ldap.attr_firstname = options["firstname_mapping"].presence
      ldap.attr_lastname = options["lastname_mapping"].presence
      ldap.attr_mail = options["mail_mapping"].presence
      ldap.attr_admin = options["admin_mapping"].presence

      ldap.save!
    end
    # rubocop:enable Metrics/AbcSize

    def update_filters(ldap, filters)
      return if filters.blank? && !LdapGroups::SynchronizedFilter.exists?(ldap_auth_source: ldap)

      upsert_existing_filters(ldap, filters) if filters.present?
      remove_not_found_filters(ldap, filters&.keys || [])
    end

    def upsert_existing_filters(ldap, filters)
      filters.each do |name, options|
        filter = ::LdapGroups::SynchronizedFilter.find_or_initialize_by(ldap_auth_source: ldap, name:)
        print_ldap_status(filter)

        filter.group_name_attribute = options.fetch("group_attribute", "dn")
        filter.sync_users = ActiveRecord::Type::Boolean.new.deserialize options.fetch("sync_users", false)
        filter.filter_string = options["filter"]
        filter.base_dn = options["base"]

        filter.save!
      end
    end

    def remove_not_found_filters(ldap, names)
      not_found = ::LdapGroups::SynchronizedFilter
        .where(ldap_auth_source: ldap)
        .where.not(name: names)

      return unless not_found.exists?

      not_found_names = not_found.pluck(:name).join(", ")
      print_status "   - Removing LDAP filter #{not_found_names} no longer present in ENV"

      not_found.destroy_all
    end

    def print_ldap_status(object)
      if object.new_record?
        print_status "   - Creating new #{object.model_name.human} #{object.name} from ENV"
      else
        print_status "   - Updating existing #{object.model_name.human} #{object.name} from ENV"
      end
    end
  end
end
