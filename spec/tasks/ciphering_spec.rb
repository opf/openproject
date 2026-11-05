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

require "spec_helper"

RSpec.describe "db ciphering" do # rubocop:disable RSpec/DescribeClass
  let!(:repository) { create(:repository_subversion, password: "repository-password") }
  let!(:ldap) { create(:ldap_auth_source, account_password: "ldap-password") }

  def with_keys(*keys, &)
    key_provider = ActiveRecord::Encryption::DerivedSecretKeyProvider.new(keys)
    ActiveRecord::Encryption.with_encryption_context(key_provider:, &)
  end

  describe "db:encrypt" do
    include_context "rake" do
      let(:task_path) { "lib/tasks/ciphering" }
    end

    let(:old_keys) { OpenProject::DatabaseEncryption.primary_keys }

    it "re-encrypts both credential types with the current key for rotation" do
      with_keys(*old_keys, "new-key") { subject.invoke }

      with_keys("new-key") do
        expect(repository.reload.password).to eq("repository-password")
        expect(ldap.reload.account_password).to eq("ldap-password")
      end

      with_keys(*old_keys) do
        expect { repository.reload.password }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
      end
    end

    it "rolls back all credentials if one cannot be decrypted" do
      ActiveRecord::Encryption.without_encryption do
        ldap.update_columns(account_password: "not-ciphertext")
      end
      stored = repository.reload.read_attribute_before_type_cast(:password)

      expect { subject.invoke }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
      expect(repository.reload.read_attribute_before_type_cast(:password)).to eq(stored)
    end
  end
end
