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
require Rails.root.join("db/migrate/20261104120000_migrate_credentials_to_active_record_encryption.rb")

RSpec.describe MigrateCredentialsToActiveRecordEncryption,
               type: :model, with_config: { "database_cipher_key" => "secret" } do
  subject(:migrate) do
    ActiveRecord::Base.transaction(requires_new: true) do
      ActiveRecord::Migration.suppress_messages { described_class.new.up }
    end
  end

  let!(:repository) { create(:repository_subversion) }
  let!(:ldap) { create(:ldap_auth_source) }
  let(:legacy) { "aes-256-cbc:w8ptVp+/egSM1uKWSLw4CA==--MDEyMzQ1Njc4OWFiY2RlZg==" }

  def store_raw(repository_value, ldap_value)
    ActiveRecord::Encryption.without_encryption do
      repository.update_columns(password: repository_value)
      ldap.update_columns(account_password: ldap_value)
    end
  end

  def raw_repository_password = repository.reload.read_attribute_before_type_cast(:password)
  def raw_ldap_password = ldap.reload.read_attribute_before_type_cast(:account_password)

  before do
    store_raw(legacy, "plaintext")
  end

  it "migrates CBC and plaintext credentials with the existing key" do
    migrate

    expect(raw_repository_password).to start_with('{"p":')
    expect(repository.password).to eq("legacy-password")
    expect(raw_ldap_password).to start_with('{"p":')
    expect(ldap.account_password).to eq("plaintext")
  end

  it "can run again without changing the credentials" do
    migrate
    migrate

    expect(repository.reload.password).to eq("legacy-password")
    expect(ldap.reload.account_password).to eq("plaintext")
  end

  it "fails on corrupt Rails ciphertext and changes nothing" do
    message = JSON.parse(LdapAuthSource.type_for_attribute(:account_password).serialize("password"))
    message["p"][0] = message["p"][0] == "A" ? "B" : "A"
    store_raw(legacy, JSON.generate(message))

    expect { migrate }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
    expect(raw_repository_password).to eq(legacy)
  end

  it "fails if the legacy key is incorrect and changes nothing" do
    store_raw("plaintext", legacy)
    with_config(database_cipher_key: "wrong")

    expect { migrate }.to raise_error(OpenSSL::Cipher::CipherError)
    expect(raw_repository_password).to eq("plaintext")
    expect(raw_ldap_password).to eq(legacy)
  end

  it "leaves nil and empty credentials as they are" do
    store_raw(nil, "")

    migrate

    expect(raw_repository_password).to be_nil
    expect(raw_ldap_password).to eq("")
  end

  it "encrypts whitespace-only credentials" do
    store_raw("\t", " ")

    migrate

    expect(raw_repository_password).to start_with('{"p":')
    expect(repository.password).to eq("\t")
    expect(raw_ldap_password).to start_with('{"p":')
    expect(ldap.account_password).to eq(" ")
  end

  context "without a legacy cipher key", with_config: { "database_cipher_key" => nil } do
    it "encrypts plaintext credentials" do
      store_raw("plaintext", "plaintext")

      migrate

      expect(raw_repository_password).to start_with('{"p":')
      expect(repository.password).to eq("plaintext")
    end
  end

  context "in production with a shipped default SECRET_KEY_BASE" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Rails.application).to receive(:secret_key_base).and_return("OVERWRITE_ME")
    end

    it "fails before it changes anything" do
      expect { migrate }.to raise_error(ArgumentError, /well-known default/)
      expect(raw_repository_password).to eq(legacy)
      expect(raw_ldap_password).to eq("plaintext")
    end
  end
end
