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

RSpec.describe "account/login" do
  context "with password login enabled" do
    before do
      render
    end

    it "shows a login field" do
      expect(rendered).to include "Password"
    end
  end

  context "with password login disabled" do
    before do
      allow(Setting).to receive(:password_login).and_return("none")
      render
    end

    it "does not show a login field" do
      expect(rendered).not_to include "Password"
    end
  end

  context "with password login disabled on the internal login page" do
    before do
      allow(Setting).to receive(:password_login).and_return("none")
      assign(:force_password_login_form, true)
      render
    end

    it "shows a login field" do
      expect(rendered).to include "Password"
    end
  end

  context "if user is not logged in" do
    before do
      User.anonymous.pref.update(settings: { "theme" => "sync_with_os" })
    end

    it "uses the OS-synced theme preference by default" do
      theme_data = view.user_theme_data_attributes

      expect(theme_data[:auto_theme_switcher_theme_value]).to eq("sync_with_os")
      # Check that contrast flags exist
      expect(theme_data).to have_key(:auto_theme_switcher_force_light_contrast_value)
      expect(theme_data).to have_key(:auto_theme_switcher_force_dark_contrast_value)
      # Check logo classes
      expect(theme_data[:auto_theme_switcher_desktop_light_high_contrast_logo_class]).to eq("op-logo--link_high_contrast")
      expect(theme_data[:auto_theme_switcher_mobile_white_logo_class]).to eq("op-logo--icon_white")
    end
  end
end
