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

RSpec.describe Collaboration::OAuth::GenerateTokenService do
  subject(:service_call) { described_class.new(user:).call }

  let(:user) { create(:user) }

  describe "#call" do
    it "creates a new access token" do
      expect { service_call }.to change(Doorkeeper::AccessToken, :count).by(1)
    end

    it "returns a successful service result" do
      result = service_call
      expect(result).to be_success
    end

    it "creates a token that belongs to the provided user" do
      result = service_call
      token = result.result

      expect(token.resource_owner_id).to eq(user.id)
    end
  end

  context "with different users" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "creates separate tokens for different users" do
      result1 = described_class.new(user: user1).call
      result2 = described_class.new(user: user2).call

      expect(result1.result.resource_owner_id).to eq(user1.id)
      expect(result2.result.resource_owner_id).to eq(user2.id)
      expect(result1.result.token).not_to eq(result2.result.token)
    end
  end
end
