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

RSpec.describe OpenIDConnect::UserTokens::CreateService do
  subject { described_class.new(user, jwt_parser: parser).call(**args) }

  let(:user) { create(:user) }

  let(:args) { { access_token:, refresh_token:, known_audiences: ["io"] } }

  let(:access_token) { "access-token-foo" }
  let(:refresh_token) { "refresh-token-bar" }

  let(:parser) { instance_double(OpenIDConnect::JwtParser, parse: Success([parsed_jwt, nil])) }
  let(:parsed_jwt) { { "aud" => ["aud1", "aud2"] } }

  before do
    allow(Rails.logger).to receive(:error)
  end

  it "creates a correct user token", :aggregate_failures do
    expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

    token = OpenIDConnect::UserToken.last
    expect(token.user_id).to eq user.id
    expect(token.access_token).to eq access_token
    expect(token.refresh_token).to eq refresh_token
    expect(token.audiences).to contain_exactly("io", "aud1", "aud2")
    expect(token.expires_at).to be_nil
  end

  it "logs no error" do
    subject
    expect(Rails.logger).not_to have_received(:error)
  end

  context "when the JWT encodes aud as a string" do
    let(:parsed_jwt) { { "aud" => "aud1" } }

    it "creates a correct user token", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.access_token).to eq access_token
      expect(token.refresh_token).to eq refresh_token
      expect(token.audiences).to contain_exactly("io", "aud1")
    end

    it "logs no error" do
      subject
      expect(Rails.logger).not_to have_received(:error)
    end
  end

  context "when the access token is not a valid JWT" do
    let(:parser) { instance_double(OpenIDConnect::JwtParser, parse: Failure("Oops, not a JWT!")) }

    it "creates a correct user token", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.access_token).to eq access_token
      expect(token.refresh_token).to eq refresh_token
      expect(token.audiences).to contain_exactly("io")
    end

    it "logs no error" do
      subject
      expect(Rails.logger).not_to have_received(:error)
    end
  end

  context "when there is no refresh token" do
    let(:refresh_token) { nil }

    it "creates a correct user token", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.user_id).to eq user.id
      expect(token.access_token).to eq access_token
      expect(token.refresh_token).to be_nil
      expect(token.audiences).to contain_exactly("io", "aud1", "aud2")
    end

    it "logs no error" do
      subject
      expect(Rails.logger).not_to have_received(:error)
    end
  end

  context "when there is no access token" do
    let(:access_token) { nil }

    it "does not create a user token" do
      expect { subject }.not_to change(OpenIDConnect::UserToken, :count)
    end

    it "logs an error" do
      subject
      expect(Rails.logger).to have_received(:error)
    end
  end

  context "when no user was passed" do
    let(:user) { nil }

    it "does not create a user token" do
      expect { subject }.not_to change(OpenIDConnect::UserToken, :count)
    end

    it "logs an error" do
      subject
      expect(Rails.logger).to have_received(:error)
    end
  end

  context "when there is no audience" do
    let(:args) { { access_token:, refresh_token:, known_audiences: [] } }

    it "creates a correct user token", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.access_token).to eq access_token
      expect(token.refresh_token).to eq refresh_token
      expect(token.audiences).to contain_exactly("aud1", "aud2")
    end

    it "logs no error" do
      subject
      expect(Rails.logger).not_to have_received(:error)
    end

    context "and the token has no audience defined" do
      let(:parsed_jwt) { { "sub" => "ject" } }

      it "does not create a user token" do
        expect { subject }.not_to change(OpenIDConnect::UserToken, :count)
      end

      it "logs no error" do
        subject
        expect(Rails.logger).not_to have_received(:error)
      end
    end
  end

  context "when another user token existed before" do
    let!(:existing_token) { user.oidc_user_tokens.create!(access_token: "existing", audiences: ["blubb"]) }

    it "keeps the existing token" do
      subject
      expect(OpenIDConnect::UserToken.find_by(id: existing_token.id)).to be_present
    end

    it "creates a correct user token", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.user_id).to eq user.id
      expect(token.access_token).to eq access_token
      expect(token.refresh_token).to eq refresh_token
      expect(token.audiences).to contain_exactly("io", "aud1", "aud2")
    end

    context "and when previous tokens shall be cleared" do
      let(:args) { { access_token:, refresh_token:, known_audiences: ["io"], clear_previous: true } }

      it "deletes the previous token" do
        subject
        expect(OpenIDConnect::UserToken.find_by(id: existing_token.id)).to be_nil
      end

      it "creates a correct user token", :aggregate_failures do
        expect { subject }.not_to change(OpenIDConnect::UserToken, :count)

        token = OpenIDConnect::UserToken.last
        expect(token.user_id).to eq user.id
        expect(token.access_token).to eq access_token
        expect(token.refresh_token).to eq refresh_token
        expect(token.audiences).to contain_exactly("io", "aud1", "aud2")
      end

      it "logs no error" do
        subject
        expect(Rails.logger).not_to have_received(:error)
      end
    end
  end

  context "when audiences from token and arguments overlap" do
    let(:parsed_jwt) { { "aud" => ["io", "aud2"] } }

    it "normalizes the audience array" do
      subject

      token = OpenIDConnect::UserToken.last
      expect(token.audiences).to contain_exactly("io", "aud2")
    end
  end

  context "when passing expires_in", :freeze_time do
    let(:args) { { access_token:, refresh_token:, known_audiences: ["io"], expires_in: } }
    let(:expires_in) { 120 }

    it "creates a user token with correct expires_at", :aggregate_failures do
      expect { subject }.to change(OpenIDConnect::UserToken, :count).by(1)

      token = OpenIDConnect::UserToken.last
      expect(token.expires_at).to eq expires_in.seconds.from_now.change(usec: 0)
    end
  end
end
