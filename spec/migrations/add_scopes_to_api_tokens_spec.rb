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
require Rails.root.join("db/migrate/20261014120437_add_scopes_to_api_tokens")

RSpec.describe AddScopesToAPITokens, type: :model do
  shared_let(:user_token) { create(:api_token, token_name: "user token") }
  shared_let(:admin_token) { create(:api_token, token_name: "admin token", user: create(:admin)) }
  shared_let(:rss_token) { create(:rss_token) }

  before do
    Token::API.update_all(data: { token_name: "legacy" })
  end

  it "grants the existing scopes to all API tokens and admin elevation to admin tokens" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(user_token.reload.scopes).to eq(%w[api_v3 mcp webhooks])
    expect(admin_token.reload.scopes).to eq(%w[api_v3 mcp webhooks admin_elevation])
  end

  it "keeps the other token data" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(user_token.reload.token_name).to eq("legacy")
  end

  it "leaves other token types untouched" do
    expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) } }
      .not_to change { rss_token.reload.data }
  end

  it "removes the scopes again on rollback" do
    ActiveRecord::Migration.suppress_messages do
      described_class.migrate(:up)
      described_class.migrate(:down)
    end

    expect(user_token.reload.data).to eq("token_name" => "legacy")
  end
end
