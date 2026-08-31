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

RSpec.describe "my routes" do
  it "/my/account GET routes to my#account" do
    expect(get("/my/account")).to route_to("my#account")
  end

  it "/my/account PATCH routes to my#update_account" do
    expect(patch("/my/account")).to route_to("my#update_account")
  end

  it "/my/locale GET routes to my#locale" do
    expect(get("/my/locale")).to route_to("my#locale")
  end

  it "/my/interface GET routes to my#interface" do
    expect(get("/my/interface")).to route_to("my#interface")
  end

  it "/my/notifications GET routes to my#notifications" do
    expect(get("/my/notifications")).to route_to("my#notifications")
  end

  it "/my/deletion_info GET routes to users#deletion_info" do
    expect(get("/my/deletion_info")).to route_to(controller: "users",
                                                 action: "deletion_info")
  end

  it "/my/settings PATCH routes to my#update_account" do
    expect(patch("/my/settings")).to route_to("my#update_settings")
  end

  context "for access tokens controller" do
    it "/my/access_tokens GET routes to my/access_tokens#index" do
      expect(get("/my/access_tokens")).to route_to("my/access_tokens#index")
    end

    it "/my/access_tokens/dialog GET routes to my/access_tokens#dialog" do
      expect(get("/my/access_tokens/dialog")).to route_to("my/access_tokens#dialog")
    end

    it "/my/generate_api_key POST routes to my/acess_tokens#generate_api_key" do
      expect(post("/my/access_tokens/generate_api_key")).to route_to("my/access_tokens#generate_api_key")
    end

    it "/my/revoke_rss_key DELETE routes to my/acess_tokens#revoke_rss_key" do
      expect(delete("/my/access_tokens/revoke_rss_key")).to route_to("my/access_tokens#revoke_rss_key")
    end

    it "/my/generate_rss_key POST routes to my/acess_tokens#generate_rss_key" do
      expect(post("/my/access_tokens/generate_rss_key")).to route_to("my/access_tokens#generate_rss_key")
    end

    it "/my/revoke_api_key DELETE routes to my/access_tokens#revoke_api_key" do
      expect(delete("/my/access_tokens/123/revoke_api_key")).to route_to("my/access_tokens#revoke_api_key",
                                                                         access_token_id: "123")
    end

    it "/my/revoke_ical_token DELETE routes to my/access_tokens#revoke_ical_token" do
      expect(delete("/my/access_tokens/123/revoke_ical_token")).to route_to("my/access_tokens#revoke_ical_token",
                                                                            access_token_id: "123")
    end

    it "/my/remove_oauth_client_token DELETE routes to my/access_tokens#remove_oauth_client_token" do
      expect(delete("/my/access_tokens/123/remove_oauth_client_token")).to route_to("my/access_tokens#remove_oauth_client_token",
                                                                               access_token_id: "123")
    end
  end
end
