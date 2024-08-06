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

class AddLdapTlsOptions < ActiveRecord::Migration[7.0]
  class MigratingAuthSource < ApplicationRecord
    self.table_name = "auth_sources"
  end

  def change
    change_table :auth_sources, bulk: true do |t|
      t.boolean :verify_peer, default: true, null: false
      t.text :tls_certificate_string
    end

    reversible do |dir|
      dir.up do
        # Current LDAP library default is to not verify the certificate
        MigratingAuthSource.reset_column_information

        ldap_settings = Setting.find_by(name: "ldap_tls_options")&.value
        migrate_ldap_settings(ldap_settings)
      end
    end
  end

  private

  def migrate_ldap_settings(ldap_settings)
    return if ldap_settings.blank?

    parsed = Setting.deserialize_hash(ldap_settings)
    verify_peer = parsed["verify_mode"] == OpenSSL::SSL::VERIFY_PEER

    MigratingAuthSource.update_all(verify_peer:)
  rescue StandardError => e
    Rails.logger.error do
      "Failed to set LDAP verify_mode from settings: #{e.message}. Please double check your LDAP configuration."
    end
  end
end
