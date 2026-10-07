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
#
require "spec_helper"

RSpec.describe Admin::Settings::UsersSettings::DefaultPreferencesForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", scope: :settings } }

  it "renders", :aggregate_failures do
    expect(page).to have_select "Default language", fieldset: "Default preferences", selected: "English" do |field|
      expect(field["name"]).to eq "settings[default_language]"
    end
    expect(page).to have_select "Users default time zone", fieldset: "Default preferences", selected: [] do |field|
      expect(field["name"]).to eq "settings[user_default_timezone]"
    end
    expect(page).to have_field "Automatically hide success banners", type: :checkbox, fieldset: "Default preferences" do |field|
      expect(field["name"]).to eq "settings[default_auto_hide_popups]"
    end
  end

  it "renders all available languages as options" do
    expect(page).to have_select "Default language" do |select|
      options = select.all(:option).to_h { [it.text, it.value] }
      expect(options).to include(
        "English" => "en",
        "Deutsch" => "de",
        "Español" => "es",
        "简体中文" => "zh-CN"
      )
    end
  end

  it "renders the timezones as options, grouping cities with the same identifier" do
    expect(page).to have_select "Users default time zone" do |select|
      options = select.all(:option).to_h { [it.text, it.value] }
      expect(options).to include(
        "(UTC-08:00) Pacific Time (US & Canada)" => "America/Los_Angeles",
        "(UTC+01:00) Berlin, Copenhagen, Stockholm" => "Europe/Berlin",
        "(UTC+08:00) Beijing, Chongqing" => "Asia/Shanghai"
      )
    end
  end

  context "when a default timezone is set", with_settings: { user_default_timezone: "Europe/Berlin" } do
    it "selects the set default timezone" do
      expect(page).to have_field "Users default time zone", with: "Europe/Berlin"
      expect(page).to have_select "Users default time zone", selected: "(UTC+01:00) Berlin, Copenhagen, Stockholm"
    end
  end
end
