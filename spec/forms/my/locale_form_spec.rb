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

RSpec.describe My::LocaleForm, type: :forms do
  before do
    travel_to(Time.utc(2026, 10, 8, 14, 15, 16))

    allow(Redmine::I18n)
      .to receive(:all_languages)
      .and_return %w[en de es ja nl zh-CN]
  end

  include_context "with rendered form"

  let(:model) { build_stubbed(:user, language:, preferences:) }
  let(:language) { nil }
  let(:preferences) { {} }

  describe "'Language' select list" do
    it "renders select list" do
      expect(page).to have_select "Language", required: true do |select|
        expect(select).to have_element :option, value: "en", text: "English", lang: "en"
        expect(select).to have_element :option, value: "de", text: "Deutsch", lang: "de"
        expect(select).to have_element :option, value: "es", text: "Español", lang: "es"
        expect(select).to have_element :option, value: "ja", text: "日本語", lang: "ja"
        expect(select).to have_element :option, value: "nl", text: "Nederlands", lang: "nl"
        expect(select).to have_element :option, value: "zh-CN", text: "简体中文", lang: "zh-CN"
      end
    end

    it "renders options sorted by CLDR name" do
      options_text = page.find(:select, "Language").all("option").map(&:text) # Capy :options filter ignores order
      expect(options_text).to eq [
        "(auto)", "Deutsch", "English", "Español", "Nederlands", "日本語", "简体中文"
      ]
    end

    it "renders options for available languages, if set", with_settings: { available_languages: %w[en es ja] } do
      expect(page).to have_select "Language", options: [
        "English",
        "Español",
        "日本語"
      ]
    end

    it "renders auto option if all languages available", with_settings: { available_languages: %w[en de es ja nl zh-CN] } do
      expect(page).to have_select "Language", with_options: ["(auto)"]
    end

    context "with no language set" do
      it "renders no selected option" do
        expect(page.find(:select, "Language")).to have_attributes(value: "")
      end
    end

    context "with language set to 'es'" do
      let(:language) { "es" }

      it "renders selected option" do
        expect(page).to have_select "Language", selected: "Español"
      end
    end
  end

  it "renders 'Time zone' select list" do
    expect(page).to have_select "Time zone", required: true
  end

  describe "'Date' select list" do
    it "renders options for all allowed formats" do
      expect(page.find(:select, "Date").all("option").map(&:text)).to eq(
        [
          "Use system or language based default",
          "2026-10-08",
          "08/10/2026",
          "08.10.2026",
          "08-10-2026",
          "10/08/2026",
          "08 Oct 2026",
          "08 October 2026",
          "Oct 08, 2026",
          "October 08, 2026"
        ]
      )
    end

    context "with no format set" do
      it "renders no selected option" do
        expect(page.find(:select, "Date")).to have_attributes(value: "")
      end
    end

    context "with format set" do
      let(:preferences) { { date_format: "%d.%m.%Y" } }

      it "renders selected option" do
        expect(page).to have_select "Date", selected: "08.10.2026"
      end
    end
  end

  describe "'Time' select list" do
    it "renders options for all allowed formats" do
      expect(page.find(:select, "Time").all("option").map(&:text)).to eq(
        [
          "Use system or language based default",
          "14:15",
          "02:15 PM"
        ]
      )
    end

    context "with no format set" do
      it "renders no selected option" do
        expect(page.find(:select, "Time")).to have_attributes(value: "")
      end
    end

    context "with format set" do
      let(:preferences) { { time_format: "%I:%M %p" } }

      it "renders selected option" do
        expect(page).to have_select "Time", selected: "02:15 PM"
      end
    end
  end

  it "renders submit button" do
    expect(page).to have_button "Save", class: "Button--primary"
  end
end
