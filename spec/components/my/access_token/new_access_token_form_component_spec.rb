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

RSpec.describe My::AccessToken::NewAccessTokenFormComponent, type: :component do
  let(:user) { build_stubbed(:user) }
  let(:token) { Token::API.new(user:, scopes: %w[api_v3]) }

  current_user { user }

  subject(:rendered) { render_inline(described_class.new(token:)) }

  it "offers the scopes without admin elevation, checking the token's scopes" do
    expect(rendered).to have_checked_field("API v3")
    expect(rendered).to have_unchecked_field("MCP")
    expect(rendered).to have_unchecked_field("Webhooks")
    expect(rendered).to have_no_field("Admin elevation")
  end

  context "for an admin" do
    let(:user) { build_stubbed(:admin) }

    it "does not offer admin elevation with the feature flag inactive" do
      expect(rendered).to have_no_field("Admin elevation")
    end

    it "offers admin elevation with the feature flag active", with_flag: { admin_privilege_elevation: true } do
      expect(rendered).to have_unchecked_field("Admin elevation")
    end
  end

  context "with an iCal meeting token" do
    let(:token) { Token::ICalMeeting.new(user:) }

    it "does not offer scopes" do
      expect(rendered).to have_no_field("API v3")
    end
  end
end
