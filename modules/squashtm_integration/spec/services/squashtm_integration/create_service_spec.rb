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

RSpec.describe SquashTMIntegration::Servers::CreateService do
  let(:user) { create(:admin) }
  let(:connection_check) { instance_double(SquashTMIntegration::ConnectionCheck, call: nil) }
  let(:params) { { base_url: "https://squashtm.example.com/squash/", api_token: "secret-token" } }

  subject(:result) { described_class.new(user:).call(params) }

  before do
    allow(SquashTMIntegration::ConnectionCheck).to receive(:new).and_return(connection_check)
  end

  it "creates the server with a normalized URL" do
    expect(result).to be_success
    expect(SquashTMIntegration::Server.sole).to have_attributes(
                                                  base_url: "https://squashtm.example.com/squash", api_token: "secret-token"
                                                )
  end

  it "fails when a server already exists" do
    create(:squashtm_server)

    expect(result).not_to be_success
    expect(result.errors).to be_added(:base, :singleton)
  end

  context "when a concurrent request inserted a server after the validation ran" do
    before do
      create(:squashtm_server, base_url: "https://first.example.com/squash")
      allow(SquashTMIntegration::Server).to receive(:exists?).and_return(false)
    end

    it "fails with the same error as the validation and keeps the first server" do
      expect(result).not_to be_success
      expect(result.errors).to be_added(:base, :singleton)
      expect(SquashTMIntegration::Server.sole.base_url).to eq("https://first.example.com/squash")
    end
  end
end
