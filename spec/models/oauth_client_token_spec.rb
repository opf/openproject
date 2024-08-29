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

RSpec.describe OAuthClientToken do
  let(:access_token) { "x" }
  let(:refresh_token) { "x" }
  let(:user) { create(:user) }
  let(:oauth_client) { create(:oauth_client) }
  let(:instance) { described_class.new(access_token:, refresh_token:, user:, oauth_client:) }

  describe "#valid?" do
    subject { instance.valid? }

    context "with default arguments" do
      it "succeeds" do
        expect(subject).to be_truthy
      end
    end

    context "with access_token too short" do
      let(:access_token) { "" }

      it "fails with access_token too short" do
        expect(subject).to be_falsey
      end
    end

    context "with refresh_token too short" do
      let(:refresh_token) { "" }

      it "fails with refresh_token too short" do
        expect(subject).to be_falsey
      end
    end

    context "without access_token" do
      let(:access_token) { nil }

      it "fails with access_token is nil" do
        expect(subject).to be_falsey
      end
    end

    context "without refresh_token" do
      let(:refresh_token) { nil }

      it "fails with refresh_token is nil" do
        expect(subject).to be_falsey
      end
    end

    context "with invalid user" do
      let(:user) { nil }

      it "fails with invalid user" do
        expect(subject).to be_falsey
      end
    end

    context "with invalid oauth_client" do
      let(:oauth_client) { nil }

      it "fails with invalid oauth_client" do
        expect(subject).to be_falsey
      end
    end
  end
end
