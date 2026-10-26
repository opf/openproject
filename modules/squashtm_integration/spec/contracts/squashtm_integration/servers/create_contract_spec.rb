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

require "spec_helper"

RSpec.describe SquashTMIntegration::Servers::CreateContract do
  let(:server) { build(:squashtm_server) }
  let(:user) { build_stubbed(:admin) }

  subject(:contract) { described_class.new(server, user) }

  it "is valid for an admin" do
    expect(contract).to be_valid
  end

  context "for a non-admin" do
    let(:user) { build_stubbed(:user) }

    it "is invalid" do
      expect(contract).not_to be_valid
      expect(contract.errors.details[:base].pluck(:error)).to include(:error_unauthorized)
    end
  end

  it "requires a URL" do
    server.base_url = ""

    expect(contract).not_to be_valid
    expect(contract.errors.details[:base_url].pluck(:error)).to include(:blank)
  end

  it "rejects a URL that is too long" do
    server.base_url = "https://squashtm.example.com/#{'a' * 256}"

    expect(contract).not_to be_valid
    expect(contract.errors.details[:base_url].pluck(:error)).to include(:too_long)
  end

  it "rejects an invalid URL" do
    server.base_url = "not a url"

    expect(contract).not_to be_valid
    expect(contract.errors.details[:base_url].pluck(:error)).to include(:url)
  end

  it "requires a secure URL" do
    server.base_url = "http://squashtm.example.com/squash"

    expect(contract).not_to be_valid
    expect(contract.errors.details[:base_url].pluck(:error)).to include(:url_not_secure_context)
  end

  it "requires an API token" do
    server.api_token = nil

    expect(contract).not_to be_valid
    expect(contract.errors.details[:api_token].pluck(:error)).to include(:blank)
  end
end
