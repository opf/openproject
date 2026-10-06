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

RSpec.describe "Allowed link protocols", :js do
  let(:admin) { create(:admin) }
  let(:always_allowed_protocols) { Setting::AllowedLinkProtocols::ALWAYS_ALLOWED }

  before do
    login_as(admin)
    visit admin_settings_general_path
  end

  it "allows updating the allowed link protocols" do
    always_allowed_protocols.each do |protocol|
      expect(Setting.allowed_link_protocols).not_to include(protocol)
      expect(Setting::AllowedLinkProtocols.all).to include(protocol)
    end

    scroll_to_element find_by_id("settings_allowed_link_protocols")

    custom_protocols = %w[ftp sftp data]
    find_by_id("settings_allowed_link_protocols").set(custom_protocols.join("\n"))

    click_on "Save"
    expect_and_dismiss_flash(message: I18n.t(:notice_successful_update))

    RequestStore.clear!
    expect(Setting.allowed_link_protocols).to match_array(custom_protocols)
    expect(Setting::AllowedLinkProtocols.all).to include(*custom_protocols)
    expect(Setting::AllowedLinkProtocols.all).to include(*always_allowed_protocols)

    scroll_to_element find_by_id("settings_allowed_link_protocols")
    custom_protocols = %w[http+ssh f[oa]x]
    find_by_id("settings_allowed_link_protocols").set(custom_protocols.join("\n"))

    click_on "Save"
    expect_and_dismiss_flash(message: I18n.t(:notice_successful_update))

    RequestStore.clear!
    expect(Setting.allowed_link_protocols).to contain_exactly("http+ssh", "foax")
  end
end
