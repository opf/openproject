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

RSpec.describe OpenIDConnect::ConfigurationMapper, type: :model do
  let(:instance) { described_class.new(configuration) }
  let(:result) { instance.call! }

  describe "display_name" do
    subject { result["display_name"] }

    context "when provided" do
      let(:configuration) { { display_name: "My OIDC Provider" } }

      it { is_expected.to eq("My OIDC Provider") }
    end

    context "when not provided" do
      let(:configuration) { {} }

      it { is_expected.to eq("OpenID Connect") }
    end
  end

  describe "slug" do
    subject { result["slug"] }

    context "when provided from name" do
      let(:configuration) { { name: "OIDCwat" } }

      it { is_expected.to eq("OIDCwat") }
    end

    context "when not provided" do
      let(:configuration) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe "client_id" do
    subject { result }

    context "when provided" do
      let(:configuration) { { identifier: "foo" } }

      it { is_expected.to include("client_id" => "foo") }
    end

    context "when not provided" do
      let(:configuration) { { foo: "bar" } }

      it { is_expected.not_to have_key("client_id") }
    end
  end

  describe "client_secret" do
    subject { result }

    context "when provided" do
      let(:configuration) { { secret: "foo" } }

      it { is_expected.to include("client_secret" => "foo") }
    end

    context "when not provided" do
      let(:configuration) { { foo: "bar" } }

      it { is_expected.not_to have_key("client_secret") }
    end
  end

  describe "issuer" do
    subject { result }

    context "when provided" do
      let(:configuration) { { issuer: "foo" } }

      it { is_expected.to include("issuer" => "foo") }
    end

    context "when not provided" do
      let(:configuration) { { foo: "bar" } }

      it { is_expected.not_to have_key("issuer") }
    end
  end

  %w[authorization_endpoint token_endpoint userinfo_endpoint end_session_endpoint jwks_uri].each do |key|
    describe "setting #{key}" do
      subject { result }

      context "when provided as url" do
        let(:configuration) { { key => "https://foo.example.com/sso" } }

        it { is_expected.to include(key => "https://foo.example.com/sso") }
      end

      context "when provided as path without host" do
        let(:configuration) { { key => "/foo" } }

        it "raises an error" do
          expect { subject }.to raise_error("Missing host in configuration")
        end
      end

      context "when provided as path with host" do
        let(:configuration) { { host: "example.com", scheme: "https", key => "/foo" } }

        it { is_expected.to include(key => "https://example.com/foo") }
      end

      context "when not provided" do
        let(:configuration) { { foo: "bar" } }

        it { is_expected.not_to have_key(key) }
      end
    end
  end
end
