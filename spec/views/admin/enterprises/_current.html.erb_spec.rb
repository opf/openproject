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

RSpec.describe "admin/enterprises/_current" do
  let(:current_user) { create(:admin) }
  let(:ee_token) { "v1_expired_with_7_days_reprieve_at_2021_09_01.token" }
  let(:current_time) { DateTime.now }

  before do
    allow(User).to receive(:current).and_return current_user

    encoded = File.read Rails.root.join("spec/fixtures/ee_tokens/#{ee_token}")
    token = EnterpriseToken.new(encoded_token: encoded)

    assign :current_token, token

    Timecop.travel(current_date) do
      render partial: "enterprises/current"
    end
  end

  context "with token still valid" do
    let(:current_date) { "2021-08-28".to_datetime }

    it "renders the token as not expired and with no reprieve days" do
      expect(rendered.to_s).to include 'data-is-expired="false"'
      expect(rendered.to_s).to include 'data-reprieve-days-left=""'
    end
  end

  context "with token just expired (within grace period)" do
    let(:current_date) { "2021-09-02".to_datetime }

    it "renders the token as expired and with 6 reprieve days" do
      expect(rendered.to_s).to include 'data-is-expired="true"'
      expect(rendered.to_s).to include 'data-reprieve-days-left="6"'
    end
  end

  context "with token expired past reprieve" do
    let(:current_date) { "2021-09-08".to_datetime }

    it "renders the token as expired and with 0 reprieve days" do
      expect(rendered.to_s).to include 'data-is-expired="true"'
      expect(rendered.to_s).to include 'data-reprieve-days-left="0"'
    end
  end

  context "with token expired and no reprieve" do
    let(:ee_token) { "v1_expired_without_reprieve_at_2021_09_01.token" }

    let(:current_date) { "2021-09-08".to_datetime }

    it "renders the token as expired and with no reprieve days" do
      expect(rendered.to_s).to include 'data-is-expired="true"'
      expect(rendered.to_s).to include 'data-reprieve-days-left=""'
    end
  end
end
