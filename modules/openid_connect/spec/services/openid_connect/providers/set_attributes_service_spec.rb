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
require_module_spec_helper

RSpec.describe OpenIDConnect::Providers::SetAttributesService, type: :model do
  let(:current_user) { build_stubbed(:admin) }

  let(:instance) do
    described_class.new(user: current_user,
                        model: model_instance,
                        contract_class:,
                        contract_options: {})
  end

  let(:call) { instance.call(params) }

  subject { call.result }

  describe "new instance" do
    let(:model_instance) { OpenIDConnect::Provider.new(oidc_provider: "custom", display_name: "foo") }
    let(:contract_class) { OpenIDConnect::Providers::CreateContract }

    describe "default attributes" do
      let(:params) { {} }

      it "sets all default attributes", :aggregate_failures do
        expect(subject.display_name).to eq "foo"
        expect(subject.slug).to eq "oidc-foo"
        expect(subject.creator).to eq(current_user)

        expect(subject.mapping_email).to be_blank
        expect(subject.mapping_first_name).to be_blank
        expect(subject.mapping_last_name).to be_blank
        expect(subject.mapping_login).to be_blank
      end
    end

    describe "setting claims" do
      let(:params) do
        {
          claims: value
        }
      end

      context "when nil" do
        let(:value) { nil }

        it "is valid" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.claims).to be_nil
        end
      end

      context "when blank" do
        let(:value) { "" }

        it "is valid" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.claims).to eq ""
        end
      end

      context "when invalid JSON" do
        let(:value) { "foo" }

        it "is invalid" do
          expect(call).not_to be_success
          expect(call.errors.details[:claims])
            .to contain_exactly({ error: :not_json })
        end
      end

      context "when valid JSON" do
        let(:value) do
          {
            id_token: {
              acr: {
                essential: true,
                values: %w[phr phrh Multi_Factor]
              }
            }
          }.to_json
        end

        it "is valid" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.claims).to eq value
        end
      end
    end

    %i[token_endpoint metadata_url jwks_uri userinfo_endpoint end_session_endpoint].each do |url_attr|
      describe "setting #{url_attr}" do
        let(:params) do
          {
            url_attr => value
          }
        end

        context "when nil" do
          let(:value) { nil }

          it "is valid" do
            expect(call).to be_success
            expect(call.errors).to be_empty

            expect(subject.public_send(url_attr)).to be_nil
          end
        end

        context "when blank" do
          let(:value) { "" }

          it "is valid" do
            expect(call).to be_success
            expect(call.errors).to be_empty

            expect(subject.public_send(url_attr)).to eq ""
          end
        end

        context "when not a URL" do
          let(:value) { "foo!" }

          it "is valid" do
            expect(call).not_to be_success
            expect(call.errors.details[url_attr])
              .to contain_exactly({ error: :url, value: })
          end
        end

        context "when invalid scheme" do
          let(:value) { "urn:some:info" }

          it "is valid" do
            expect(call).not_to be_success
            expect(call.errors.details[url_attr])
              .to contain_exactly({ error: :url, value: })
          end
        end

        context "when valid" do
          let(:value) { "https://foobar.example.com/slo" }

          it "is valid" do
            expect(call).to be_success
            expect(call.errors).to be_empty

            expect(subject.public_send(url_attr)).to eq value
          end
        end
      end
    end
  end
end
