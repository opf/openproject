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

RSpec.describe LdapAuthSource do
  it "creates" do
    a = described_class.new(name: "My LDAP", host: "ldap.example.net", port: 389, base_dn: "dc=example,dc=net",
                            attr_login: "sAMAccountName")
    expect(a.save).to be true
  end

  it "strips ldap attributes" do
    a = described_class.new(name: "My LDAP", host: "ldap.example.net", port: 389,
                            base_dn: "dc=example,dc=net", attr_login: "sAMAccountName",
                            attr_firstname: "givenName ")
    expect(a.save).to be true
    expect(a.reload.attr_firstname).to eq "givenName"
  end

  describe "verify_peer" do
    let(:tls_mode) { :start_tls }
    let(:ldap) { described_class.new tls_mode:, verify_peer: }

    subject { ldap.ldap_connection_options[:encryption] }

    context "when set" do
      let(:verify_peer) { true }

      it "reflects in tls_options" do
        expect(subject).to have_key :tls_options
        expect(subject[:tls_options]).to match(hash_including(verify_mode: OpenSSL::SSL::VERIFY_PEER))
      end
    end

    context "when set, but tls_mode differs" do
      let(:tls_mode) { :plain_ldap }
      let(:verify_peer) { true }

      it "does nothing" do
        expect(subject).to be_nil
      end
    end

    context "when unset" do
      let(:verify_peer) { false }

      it "reflects in tls_options" do
        expect(subject).to have_key :tls_options
        expect(subject[:tls_options]).to match(hash_including(verify_mode: OpenSSL::SSL::VERIFY_NONE))
      end
    end
  end

  describe "cert_store" do
    let(:fixture) { Rails.root.join("spec/fixtures/ldap/snakeoil.pem") }
    let(:ldap) { build(:ldap_auth_source, tls_mode: :start_tls, tls_certificate_string: File.read(fixture)) }
    let(:store_double) { instance_double(OpenSSL::X509::Store) }

    subject { ldap.ldap_connection_options.dig(:encryption, :tls_options) }

    it "adds the certificates to the store" do
      allow(OpenSSL::X509::Store).to receive(:new).and_return(store_double)
      allow(store_double).to receive(:set_default_paths)
      allow(store_double).to receive(:add_cert)

      expect(subject).to have_key :cert_store
      expect(subject[:cert_store]).to eq store_double

      expect(store_double).to have_received(:add_cert).twice
    end
  end

  describe "tls_certificate_string" do
    let(:ldap) { build(:ldap_auth_source, tls_certificate_string:) }

    subject { ldap.read_ldap_certificates }

    context "when single certificate" do
      let(:fixture) { Rails.root.join("spec/fixtures/ldap/snakeoil.pem") }
      let(:tls_certificate_string) { File.read(fixture).split(/^$/)[0] }

      it "is valid" do
        expect(ldap).to be_valid
        expect(subject).to be_a Array
        expect(subject.length).to eq 1
        expect(subject).to all(be_a(OpenSSL::X509::Certificate))
      end
    end

    context "when multiple certificates" do
      let(:fixture) { Rails.root.join("spec/fixtures/ldap/snakeoil.pem") }
      let(:tls_certificate_string) { File.read(fixture) }

      it "is valid" do
        expect(ldap).to be_valid
        expect(subject).to be_a Array
        expect(subject.length).to eq 2
        expect(subject).to all(be_a(OpenSSL::X509::Certificate))
      end
    end

    context "when bogus content" do
      let(:tls_certificate_string) { "foo" }

      it "is invalid" do
        expect(ldap).not_to be_valid
        expect { subject }.to raise_error(OpenSSL::X509::CertificateError)
      end
    end
  end

  describe "admin attribute mapping" do
    let(:auth_source) do
      build(:ldap_auth_source,
            attr_login: "uid",
            attr_firstname: "givenName",
            attr_lastname: "sn",
            attr_mail: "mail",
            attr_admin:)
    end
    let(:entry) do
      Net::LDAP::Entry.new("uid=login,foo=bar").tap do |entry|
        entry["uid"] = "login"
        entry["givenName"] = "abc"
        entry["sn"] = "lastname"
        entry["mail"] = "some@example.org"
        entry["admin"] = admin_value
      end
    end

    subject { auth_source.get_user_attributes_from_ldap_entry(entry) }

    context "when attribute defined and not present" do
      let(:attr_admin) { "admin" }
      let(:admin_value) { nil }

      it "returns it as false" do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be false
      end
    end

    context "when attribute defined and castable number" do
      let(:attr_admin) { "admin" }
      let(:admin_value) { "1" }

      it "does return the mapping" do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be true
      end
    end

    context "when attribute defined and boolean" do
      let(:attr_admin) { "admin" }
      let(:admin_value) { false }

      it "does return the mapping" do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be false
      end
    end

    context "when attribute defined and true string" do
      let(:attr_admin) { "admin" }
      let(:admin_value) { "true" }

      it "does return the mapping" do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be true
      end
    end

    context "when attribute defined and false string" do
      let(:attr_admin) { "admin" }
      let(:admin_value) { "false" }

      it "does return the mapping" do
        expect(subject).to have_key(:admin)
        expect(subject[:admin]).to be false
      end
    end

    context "when attribute not defined and set" do
      let(:attr_admin) { nil }
      let(:admin_value) { true }

      it "does not return an admin mapping" do
        expect(subject).not_to have_key(:admin)
      end
    end
  end

  describe "with live LDAP", skip_if_command_unavailable: "java" do
    before(:all) do
      ldif = Rails.root.join("spec/fixtures/ldap/users.ldif")
      @ldap_server = Ladle::Server.new(quiet: false, port: ParallelHelper.port_for_ldap.to_s, domain: "dc=example,dc=com",
                                       ldif:).start
    end

    after(:all) do
      @ldap_server&.stop # rubocop:disable RSpec/InstanceVariable
    end

    # Ldap has three users aa729, bb459, cc414
    let(:ldap) do
      create(:ldap_auth_source,
             port: ParallelHelper.port_for_ldap.to_s,
             tls_mode: :plain_ldap,
             account: "uid=admin,ou=system",
             account_password: "secret",
             base_dn: "ou=people,dc=example,dc=com",
             filter_string:,
             onthefly_register:,
             attr_login: "uid",
             attr_firstname: "givenName",
             attr_lastname: "sn",
             attr_mail: "mail",
             attr_admin:)
    end

    let(:onthefly_register) { true }
    let(:filter_string) { nil }
    let(:attr_admin) { nil }

    describe "attr_admin" do
      context "when set" do
        let(:attr_admin) { "isAdmin" }

        it "maps for the admin user in ldap", :aggregate_failures do
          admin = ldap.find_user("ldap_admin")
          expect(admin).to be_a User
          expect(admin.firstname).to eq "LDAP"
          expect(admin.lastname).to eq "Adminuser"
          expect(admin.admin).to eq true

          user = ldap.find_user("bb459")
          expect(user).to be_a User
          expect(user.firstname).to eq "Belle"
          expect(user.lastname).to eq "Baldwin"
          expect(user.admin).to eq false
        end

        context "with an existing user and different attributes" do
          let!(:user) { create(:user, ldap_auth_source: ldap, login: "ldap_admin") }

          it "updates the user" do
            expect(user.firstname).to eq "Bob"
            expect(user).not_to be_admin

            ldap.find_user("ldap_admin")
            user.reload
            expect(user).to be_a User
            expect(user.firstname).to eq "LDAP"
            expect(user.lastname).to eq "Adminuser"
            expect(user).to be_admin
            expect(user.ldap_auth_source_id).to eq ldap.id
          end
        end
      end
    end

    describe "looking up and authenticating users" do
      context "with a valid LDAP user" do
        it "authenticates the user" do
          user = ldap.authenticate("bb459", "niwdlab")
          expect(user).to be_a User
          expect(user.firstname).to eq "Belle"
          expect(user.lastname).to eq "Baldwin"
          expect(user.mail).to eq "belle@example.org"
          expect(user.ldap_auth_source_id).to eq ldap.id
        end

        it "finds the user" do
          user = ldap.find_user("bb459")
          expect(user).to be_a User
          expect(user.firstname).to eq "Belle"
          expect(user.lastname).to eq "Baldwin"
          expect(user.mail).to eq "belle@example.org"
          expect(user.ldap_auth_source_id).to eq ldap.id
        end
      end

      context "with an existing user and different attributes" do
        let!(:user) { create(:user, ldap_auth_source: ldap, login: "bb459") }

        it "updates the user" do
          expect(user.firstname).to eq "Bob"

          ldap.find_user("bb459")
          user.reload
          expect(user).to be_a User
          expect(user.firstname).to eq "Belle"
          expect(user.lastname).to eq "Baldwin"
          expect(user.mail).to eq "belle@example.org"
          expect(user.ldap_auth_source_id).to eq ldap.id
        end
      end

      context "with a valid LDAP user that exists, but not for the ldap connection" do
        let!(:other_ldap) { create(:ldap_auth_source, name: "other") }
        let!(:user) { create(:user, ldap_auth_source: other_ldap, login: "bb459") }

        it "does not authenticate as the user does not exist for the ldap" do
          user = ldap.authenticate("bb459", "niwdlab")
          expect(user).to be_nil
        end

        it "does not find as the user does not exist for the ldap" do
          user = ldap.find_user("bb459")
          expect(user).to be_nil
        end
      end

      context "when the LDAP is not onthefly_register" do
        let(:onthefly_register) { false }

        context "with a valid LDAP user that does not exist" do
          it "does not authenticate as the user does not exist" do
            user = ldap.authenticate("bb459", "niwdlab")
            expect(user).to be_nil
          end

          it "does not find as the user does not exist" do
            user = ldap.find_user("bb459")
            expect(user).to be_nil
          end
        end

        context "with a valid LDAP user that exists, but not for the ldap connection" do
          let!(:other_ldap) { create(:ldap_auth_source, name: "other") }
          let!(:user) { create(:user, ldap_auth_source: other_ldap, login: "bb459") }

          it "does not authenticate as the user does not exist for the ldap" do
            user = ldap.authenticate("bb459", "niwdlab")
            expect(user).to be_nil
          end

          it "does not find as the user does not exist for the ldap" do
            user = ldap.find_user("bb459")
            expect(user).to be_nil
          end
        end
      end

      context "with the wrong LDAP user password" do
        it "does not authenticate" do
          user = ldap.authenticate("bb459", "asdf")
          expect(user).to be_nil
        end
      end

      context "with an invalid LDAP user" do
        it "returns nil for authenticate" do
          expect(ldap.authenticate("nouser", "whatever")).to be_nil
        end

        it "returns nil for find_user" do
          expect(ldap.find_user("nouser")).to be_nil
        end
      end

      context "without a login" do
        it "returns nil for authenticate" do
          expect(ldap.authenticate("", "whatever")).to be_nil
        end

        it "returns nil for find_user" do
          expect(ldap.find_user("")).to be_nil
        end
      end

      context "without a password" do
        it "returns nil" do
          expect(ldap.authenticate("whatever", "nil")).to be_nil
        end
      end

      context "with a filter string returning only users with a*" do
        let(:filter_string) { "(uid=a*)" }

        it "no longer authenticates bb459" do
          expect(ldap.authenticate("bb459", "niwdlab")).to be_nil
        end

        it "no longer finds bb254" do
          expect(ldap.find_user("bb459")).to be_nil
        end

        it "still finds aa729" do
          user = ldap.find_user("aa729")
          expect(user).to be_a User
          expect(user.firstname).to eq "Alexandra"
        end

        it "still authenticates aa729" do
          user = ldap.authenticate("aa729", "smada")
          expect(user).to be_a User
          expect(user.firstname).to eq "Alexandra"
        end
      end
    end
  end
end
