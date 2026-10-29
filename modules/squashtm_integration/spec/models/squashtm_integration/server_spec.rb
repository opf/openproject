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

RSpec.describe SquashTMIntegration::Server do
  describe "#api_token", with_config: { "database_cipher_key" => "secret" } do
    let(:server) { create(:squashtm_server, api_token: "plain-token") }

    it "is encrypted at rest" do
      expect(server.read_attribute(:api_token)).to start_with("aes-256-cbc:")
      expect(server.read_attribute(:api_token)).not_to include("plain-token")
    end

    it "is decrypted when read" do
      expect(described_class.find(server.id).api_token).to eq("plain-token")
    end

    it "stays empty when blank" do
      server.api_token = ""

      expect(server.read_attribute(:api_token)).to be_nil
    end
  end

  describe "#api_token_stored?" do
    it "is false for a new server" do
      expect(build(:squashtm_server)).not_to be_api_token_stored
    end

    it "is true for a saved server with a token" do
      expect(create(:squashtm_server)).to be_api_token_stored
    end
  end

  describe ".current" do
    it "returns the configured server" do
      server = create(:squashtm_server)

      expect(described_class.current).to eq(server)
    end

    it "returns a new server when none is configured" do
      expect(described_class.current).to be_new_record
    end
  end

  it "rejects a second server at the database level when the validation is bypassed" do
    create(:squashtm_server)

    expect do
      described_class.transaction(requires_new: true) { build(:squashtm_server).save!(validate: false) }
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows only one server" do
    create(:squashtm_server)

    second = build(:squashtm_server)

    expect(second).not_to be_valid
    expect(second.errors).to be_added(:base, :singleton)
  end

  it "links a SquashTM project to its information page" do
    server = build(:squashtm_server, base_url: "https://squashtm.example.com/squash")

    expect(server.project_url(7))
      .to eq("https://squashtm.example.com/squash/administration-workspace/projects/7/content?anchor=information")
  end
end
