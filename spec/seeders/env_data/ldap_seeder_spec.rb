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

require "spec_helper"

RSpec.describe EnvData::LdapSeeder do
  let(:seed_data) { Source::SeedData.new({}) }

  subject(:seeder) { described_class.new(seed_data) }

  context "when not provided" do
    it "does nothing" do
      expect { seeder.seed! }.not_to change(LdapAuthSource, :count)
    end
  end

  context "when providing seed variables",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_LDAP_FOO_HOST: "localhost",
            OPENPROJECT_SEED_LDAP_FOO_PORT: "12389",
            OPENPROJECT_SEED_LDAP_FOO_SECURITY: "plain_ldap",
            OPENPROJECT_SEED_LDAP_FOO_TLS__VERIFY: "false",
            OPENPROJECT_SEED_LDAP_FOO_TLS__CERTIFICATE: Rails.root.join("spec/fixtures/files/example.com.crt").read,
            OPENPROJECT_SEED_LDAP_FOO_BINDUSER: "uid=admin,ou=system",
            OPENPROJECT_SEED_LDAP_FOO_BINDPASSWORD: "secret",
            OPENPROJECT_SEED_LDAP_FOO_BASEDN: "dc=example,dc=com",
            OPENPROJECT_SEED_LDAP_FOO_FILTER: "(uid=*)",
            OPENPROJECT_SEED_LDAP_FOO_SYNC__USERS: "true",
            OPENPROJECT_SEED_LDAP_FOO_LOGIN__MAPPING: "uid",
            OPENPROJECT_SEED_LDAP_FOO_FIRSTNAME__MAPPING: "givenName",
            OPENPROJECT_SEED_LDAP_FOO_LASTNAME__MAPPING: "sn",
            OPENPROJECT_SEED_LDAP_FOO_MAIL__MAPPING: "mail",
            OPENPROJECT_SEED_LDAP_FOO_ADMIN__MAPPING: "is_openproject_admin",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_BASE: "ou=groups,dc=example,dc=com",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_FILTER: "(cn=*)",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_SYNC__USERS: "true",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_BAR_GROUP__ATTRIBUTE: "dn"
          } do
    it "uses those variables" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      reset(:seed_ldap)

      allow(LdapGroups::SynchronizationJob).to receive(:perform_now)

      seeder.seed!

      expect(LdapGroups::SynchronizationJob).to have_received(:perform_now)

      ldap = LdapAuthSource.last
      expect(ldap.name).to eq "foo"
      expect(ldap.host).to eq "localhost"
      expect(ldap.port).to eq 12389
      expect(ldap.tls_mode).to eq "plain_ldap"
      expect(ldap.read_ldap_certificates.first).to be_a(OpenSSL::X509::Certificate)
      expect(ldap.verify_peer).to be false
      expect(ldap.account).to eq "uid=admin,ou=system"
      expect(ldap.account_password).to eq "secret"
      expect(ldap.base_dn).to eq "dc=example,dc=com"
      expect(ldap.filter_string).to eq "(uid=*)"
      expect(ldap).to be_onthefly_register
      expect(ldap.attr_login).to eq "uid"
      expect(ldap.attr_firstname).to eq "givenName"
      expect(ldap.attr_lastname).to eq "sn"
      expect(ldap.attr_mail).to eq "mail"
      expect(ldap.attr_admin).to eq "is_openproject_admin"

      expect(ldap.ldap_groups_synchronized_filters.count).to eq(1)
      filter = ldap.ldap_groups_synchronized_filters.first
      expect(filter.name).to eq "bar"
      expect(filter.base_dn).to eq "ou=groups,dc=example,dc=com"
      expect(filter.filter_string).to eq "(cn=*)"
      expect(filter.sync_users).to be true
      expect(filter.group_name_attribute).to eq "dn"
    end
  end

  context "when providing seed variables with a complex password",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_LDAP_FOO_HOST: "localhost",
            OPENPROJECT_SEED_LDAP_FOO_PORT: "12389",
            OPENPROJECT_SEED_LDAP_FOO_SECURITY: "plain_ldap",
            OPENPROJECT_SEED_LDAP_FOO_TLS__VERIFY: "false",
            OPENPROJECT_SEED_LDAP_FOO_TLS__CERTIFICATE: Rails.root.join("spec/fixtures/files/example.com.crt").read,
            OPENPROJECT_SEED_LDAP_FOO_BINDUSER: "uid=admin,ou=system",
            OPENPROJECT_SEED_LDAP_FOO_BINDPASSWORD: "*@foo1$2^$§#EXxd!c*!",
            OPENPROJECT_SEED_LDAP_FOO_BASEDN: "dc=example,dc=com",
            OPENPROJECT_SEED_LDAP_FOO_FILTER: "(uid=*)",
            OPENPROJECT_SEED_LDAP_FOO_SYNC__USERS: "true",
            OPENPROJECT_SEED_LDAP_FOO_LOGIN__MAPPING: "uid",
            OPENPROJECT_SEED_LDAP_FOO_FIRSTNAME__MAPPING: "givenName",
            OPENPROJECT_SEED_LDAP_FOO_LASTNAME__MAPPING: "sn",
            OPENPROJECT_SEED_LDAP_FOO_MAIL__MAPPING: "mail",
            OPENPROJECT_SEED_LDAP_FOO_ADMIN__MAPPING: "is_openproject_admin"
          } do
    it "allows parsing of that password" do
      reset(:seed_ldap)

      allow(LdapGroups::SynchronizationJob).to receive(:perform_now)

      seeder.seed!

      expect(LdapGroups::SynchronizationJob).to have_received(:perform_now)

      ldap = LdapAuthSource.last
      expect(ldap.account_password).to eq "*@foo1$2^$§#EXxd!c*!"
    end
  end

  context "when removing a previously seeded filter",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_LDAP_FOO_HOST: "localhost",
            OPENPROJECT_SEED_LDAP_FOO_PORT: "12389",
            OPENPROJECT_SEED_LDAP_FOO_SECURITY: "plain_ldap",
            OPENPROJECT_SEED_LDAP_FOO_TLS__VERIFY: "false",
            OPENPROJECT_SEED_LDAP_FOO_BINDUSER: "uid=admin,ou=system",
            OPENPROJECT_SEED_LDAP_FOO_BINDPASSWORD: "secret",
            OPENPROJECT_SEED_LDAP_FOO_BASEDN: "dc=example,dc=com",
            OPENPROJECT_SEED_LDAP_FOO_FILTER: "(uid=*)",
            OPENPROJECT_SEED_LDAP_FOO_SYNC__USERS: "true",
            OPENPROJECT_SEED_LDAP_FOO_LOGIN__MAPPING: "uid",
            OPENPROJECT_SEED_LDAP_FOO_FIRSTNAME__MAPPING: "givenName",
            OPENPROJECT_SEED_LDAP_FOO_LASTNAME__MAPPING: "sn",
            OPENPROJECT_SEED_LDAP_FOO_MAIL__MAPPING: "mail"
          } do
    let!(:ldap) { create(:ldap_auth_source, name: "foo") }
    let!(:filter) { create(:ldap_synchronized_filter, name: "bar", ldap_auth_source: ldap) }

    it "removes the other one" do # rubocop:disable RSpec/MultipleExpectations
      expect(ldap.ldap_groups_synchronized_filters.count).to eq(1)
      names = ldap.ldap_groups_synchronized_filters.pluck(:name)
      expect(names).to contain_exactly("bar")

      reset(:seed_ldap)

      allow(LdapGroups::SynchronizationJob).to receive(:perform_now)

      seeder.seed!

      expect(LdapGroups::SynchronizationJob).to have_received(:perform_now)

      ldap.reload
      expect(ldap.name).to eq "foo"
      expect(ldap.host).to eq "localhost"
      expect(ldap.port).to eq 12389
      expect(ldap.tls_mode).to eq "plain_ldap"
      expect(ldap.verify_peer).to be false
      expect(ldap.account).to eq "uid=admin,ou=system"
      expect(ldap.account_password).to eq "secret"
      expect(ldap.base_dn).to eq "dc=example,dc=com"
      expect(ldap.filter_string).to eq "(uid=*)"
      expect(ldap).to be_onthefly_register
      expect(ldap.attr_login).to eq "uid"
      expect(ldap.attr_firstname).to eq "givenName"
      expect(ldap.attr_lastname).to eq "sn"
      expect(ldap.attr_mail).to eq "mail"
      expect(ldap.attr_admin).to be_nil

      expect(ldap.ldap_groups_synchronized_filters.count).to eq(0)
    end
  end

  context "when removing a previously seeded filter and adding one",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_LDAP_FOO_HOST: "localhost",
            OPENPROJECT_SEED_LDAP_FOO_PORT: "12389",
            OPENPROJECT_SEED_LDAP_FOO_SECURITY: "plain_ldap",
            OPENPROJECT_SEED_LDAP_FOO_TLS__VERIFY: "false",
            OPENPROJECT_SEED_LDAP_FOO_BINDUSER: "uid=admin,ou=system",
            OPENPROJECT_SEED_LDAP_FOO_BINDPASSWORD: "secret",
            OPENPROJECT_SEED_LDAP_FOO_BASEDN: "dc=example,dc=com",
            OPENPROJECT_SEED_LDAP_FOO_FILTER: "(uid=*)",
            OPENPROJECT_SEED_LDAP_FOO_SYNC__USERS: "true",
            OPENPROJECT_SEED_LDAP_FOO_LOGIN__MAPPING: "uid",
            OPENPROJECT_SEED_LDAP_FOO_FIRSTNAME__MAPPING: "givenName",
            OPENPROJECT_SEED_LDAP_FOO_LASTNAME__MAPPING: "sn",
            OPENPROJECT_SEED_LDAP_FOO_MAIL__MAPPING: "mail",
            OPENPROJECT_SEED_LDAP_FOO_ADMIN__MAPPING: "",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_ANOTHER_BASE: "ou=groups,dc=example,dc=com",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_ANOTHER_FILTER: "(cn=*)",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_ANOTHER_SYNC__USERS: "true",
            OPENPROJECT_SEED_LDAP_FOO_GROUPFILTER_ANOTHER_GROUP__ATTRIBUTE: "dn"
          } do
    let!(:ldap) { create(:ldap_auth_source, name: "foo") }
    let!(:filter) { create(:ldap_synchronized_filter, name: "bar", ldap_auth_source: ldap) }

    it "removes the other one" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      expect(ldap.ldap_groups_synchronized_filters.count).to eq(1)
      names = ldap.ldap_groups_synchronized_filters.pluck(:name)
      expect(names).to contain_exactly("bar")

      reset(:seed_ldap)

      allow(LdapGroups::SynchronizationJob).to receive(:perform_now)

      seeder.seed!

      expect(LdapGroups::SynchronizationJob).to have_received(:perform_now)

      ldap.reload
      expect(ldap.name).to eq "foo"
      expect(ldap.host).to eq "localhost"
      expect(ldap.port).to eq 12389
      expect(ldap.tls_mode).to eq "plain_ldap"
      expect(ldap.verify_peer).to be false
      expect(ldap.account).to eq "uid=admin,ou=system"
      expect(ldap.account_password).to eq "secret"
      expect(ldap.base_dn).to eq "dc=example,dc=com"
      expect(ldap.filter_string).to eq "(uid=*)"
      expect(ldap).to be_onthefly_register
      expect(ldap.attr_login).to eq "uid"
      expect(ldap.attr_firstname).to eq "givenName"
      expect(ldap.attr_lastname).to eq "sn"
      expect(ldap.attr_mail).to eq "mail"
      expect(ldap.attr_admin).to be_nil

      expect(ldap.ldap_groups_synchronized_filters.count).to eq(1)
      names = ldap.ldap_groups_synchronized_filters.pluck(:name)
      expect(names).to contain_exactly("another")
    end
  end
end
