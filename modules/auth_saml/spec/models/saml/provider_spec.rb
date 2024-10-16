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
require_module_spec_helper

RSpec.describe Saml::Provider do
  let(:instance) { described_class.new(display_name: "saml", slug: "saml") }

  describe "#seeded_from_env?" do
    subject { instance.seeded_from_env? }

    context "when the provider is not seeded from the environment" do
      it { is_expected.to be false }
    end

    context "when the provider is seeded from the environment",
            with_settings: { seed_saml_provider: { saml: {} } } do
      it { is_expected.to be true }
    end
  end

  describe "#has_metadata?" do
    subject { instance.has_metadata? }

    context "when metadata_xml is set" do
      before { instance.metadata_xml = "metadata" }

      it { is_expected.to be true }
    end

    context "when metadata_url is set" do
      before { instance.metadata_url = "metadata" }

      it { is_expected.to be true }
    end

    context "when metadata_xml and metadata_url are not set" do
      it { is_expected.to be false }
    end
  end

  describe "#metadata_changed?" do
    subject { instance.metadata_updated? }

    context "when metadata_xml is changed" do
      before { instance.metadata_xml = "metadata" }

      it { is_expected.to be true }
    end

    context "when metadata_url is changed" do
      before { instance.metadata_url = "metadata" }

      it { is_expected.to be true }
    end

    context "when metadata_xml and metadata_url are not changed" do
      it { is_expected.to be false }
    end
  end

  describe "#metadata_endpoint", with_settings: { host_name: "example.com" } do
    subject { instance.metadata_endpoint }

    it { is_expected.to eq "http://example.com/auth/saml/metadata" }
  end

  describe "#configured?" do
    subject { instance.configured? }

    context "when fully present" do
      let(:instance) { build_stubbed(:saml_provider) }

      it { is_expected.to be true }
    end

    context "when details missing" do
      it { is_expected.to be false }
    end
  end

  describe "#mapping_configured?" do
    subject { instance.mapping_configured? }

    context "when fully present" do
      let(:instance) { build_stubbed(:saml_provider) }

      it { is_expected.to be true }
    end

    context "when parts missing" do
      before do
        instance.mapping_mail = "foo"
      end

      it { is_expected.to be false }
    end

    context "when optional uid missing" do
      before do
        instance.mapping_mail = "foo"
        instance.mapping_login = "foo"
        instance.mapping_firstname = "foo"
        instance.mapping_lastname = "foo"
      end

      it { is_expected.to be true }
    end
  end

  describe "#loaded_certificate" do
    subject { instance.loaded_certificate }

    before do
      instance.certificate = certificate
    end

    context "when blank" do
      let(:certificate) { nil }

      it { is_expected.to be_nil }
    end

    context "when present" do
      let(:certificate) { CertificateHelper.valid_certificate.to_pem }

      it { is_expected.to be_a(OpenSSL::X509::Certificate) }
    end

    context "when invalid" do
      let(:certificate) { "invalid" }

      it "raises an error" do
        expect { subject }.to raise_error(OpenSSL::X509::CertificateError)
      end
    end
  end

  describe "#loaded_private_key" do
    subject { instance.loaded_private_key }

    before do
      instance.private_key = private_key
    end

    context "when blank" do
      let(:private_key) { nil }

      it { is_expected.to be_nil }
    end

    context "when present" do
      let(:private_key) { CertificateHelper.private_key.private_to_pem }

      it { is_expected.to be_a(OpenSSL::PKey::RSA) }
    end

    context "when invalid" do
      let(:private_key) { "invalid" }

      it "raises an error" do
        expect { subject }.to raise_error(OpenSSL::PKey::RSAError)
      end
    end
  end

  describe "#loaded_idp_certificates" do
    subject { instance.loaded_idp_certificates }

    before do
      instance.idp_cert = certificate
    end

    context "when blank" do
      let(:certificate) { nil }

      it { is_expected.to be_nil }
    end

    context "when single" do
      let(:certificate) { CertificateHelper.valid_certificate.to_pem }

      it "is an array of one certificate", :aggregate_failures do
        expect(subject).to be_a(Array)
        expect(subject.count).to eq(1)
        expect(subject).to all(be_a(OpenSSL::X509::Certificate))
      end
    end

    context "when multi" do
      let(:input) { CertificateHelper.valid_certificate.to_pem }
      let(:certificate) { "#{input}\n#{input}" }

      it "is an array of two certificates", :aggregate_failures do
        expect(subject).to be_a(Array)
        expect(subject.count).to eq(2)
        expect(subject).to all(be_a(OpenSSL::X509::Certificate))
      end
    end

    context "when invalid" do
      let(:certificate) { "invalid" }

      it "raises an error" do
        expect { subject }.to raise_error(OpenSSL::X509::CertificateError)
      end
    end
  end

  describe "#idp_certificate_valid?" do
    subject { instance.idp_certificate_valid? }

    before do
      instance.idp_cert = certificate
    end

    context "when blank" do
      let(:certificate) { nil }

      it { is_expected.to be false }
    end

    context "when single valid" do
      let(:certificate) { CertificateHelper.valid_certificate.to_pem }

      it { is_expected.to be true }
    end

    context "when single expired" do
      let(:certificate) { CertificateHelper.expired_certificate.to_pem }

      it { is_expected.to be false }
    end

    context "when first valid, second expired" do
      let(:valid) { CertificateHelper.valid_certificate.to_pem }
      let(:invalid) { CertificateHelper.expired_certificate.to_pem }
      let(:certificate) { "#{valid}\n#{invalid}" }

      it { is_expected.to be true }
    end

    context "when first expired, second valid" do
      let(:valid) { CertificateHelper.valid_certificate.to_pem }
      let(:invalid) { CertificateHelper.expired_certificate.to_pem }
      let(:certificate) { "#{invalid}\n#{valid}" }

      it { is_expected.to be true }
    end

    context "when both expired" do
      let(:invalid) { CertificateHelper.expired_certificate.to_pem }
      let(:certificate) { "#{invalid}\n#{invalid}" }

      it { is_expected.to be false }
    end
  end
end
