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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class MigrateCredentialsToActiveRecordEncryption < ActiveRecord::Migration[8.1]
  class MigratedRepository < ActiveRecord::Base
    self.table_name = "repositories"
    self.inheritance_column = nil
    encrypts :password
  end

  class MigratedLdapAuthSource < ActiveRecord::Base
    self.table_name = "ldap_auth_sources"
    encrypts :account_password
  end

  def up
    OpenProject::DatabaseEncryption.validate_secret!

    change_column :repositories, :password, :text
    change_column :ldap_auth_sources, :account_password, :text

    MigratedRepository.reset_column_information
    MigratedLdapAuthSource.reset_column_information

    encrypt_credentials(MigratedRepository, :password)
    encrypt_credentials(MigratedLdapAuthSource, :account_password)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Older versions cannot read Active Record encrypted credentials"
  end

  private

  def encrypt_credentials(model, attribute)
    type = model.type_for_attribute(attribute)

    select_rows(model.select(:id, attribute).to_sql).each do |id, raw|
      next if raw.blank?

      clear = type.encrypted?(raw) ? type.deserialize(raw) : Redmine::Ciphering.decrypt_text(raw)
      model.where(id:).update_all(attribute => clear)
    end
  end
end
