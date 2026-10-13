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

RSpec.describe My::AccessToken::API::TableComponent, type: :component do
  let(:user) { create(:user, preferences: { time_zone: "Europe/Berlin" }) }
  let(:berlin) { Time.find_zone("Europe/Berlin") }

  current_user { user }

  subject(:rendered) do
    render_inline(described_class.new(rows: [token], title: "API tokens", token_type: token.class))
  end

  context "with an API token without expiry" do
    let(:token) { create(:api_token, user:) }

    it "shows that it never expires" do
      expect(rendered).to have_text("Never")
    end
  end

  context "with an API token expiring in the future", with_settings: { date_format: "%Y-%m-%d" } do
    let(:expiry_date) { berlin.today + 7.days }
    let(:token) { create(:api_token, user:, expires_on_date: expiry_date) }

    it "shows the expiry date" do
      expect(rendered).to have_text(expiry_date.iso8601)
      expect(rendered).to have_no_text("Expired")
    end
  end

  context "with an expired API token", with_settings: { date_format: "%Y-%m-%d" } do
    let(:expiry_date) { berlin.today - 2.days }
    let(:token) do
      create(:api_token, user:).tap { it.update_column(:expires_on, expiry_date.in_time_zone(berlin).end_of_day) }
    end

    it "shows when it expired" do
      expect(rendered).to have_text("Expired on #{expiry_date.iso8601}")
    end
  end

  context "with an RSS token" do
    let(:token) { create(:rss_token, user:) }

    it "shows that it never expires" do
      expect(rendered).to have_text("Never")
    end
  end
end
