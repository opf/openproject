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

RSpec.describe "Languages settings page", :cuprite, :js do
  current_user { create(:admin) }

  let(:languages_page) { Pages::Admin::SystemSettings::Languages.new }

  context "when available languages setting is writable" do
    before do
      Setting.default_language = "fr"
      Setting.available_languages = %w[de en]
    end

    it "adds default language to available languages when saving" do
      languages_page.visit!

      expect(languages_page).to have_field("available_languages_de", checked: true)
      expect(languages_page).to have_field("available_languages_en", checked: true)
      expect(languages_page).to have_field("available_languages_fr", checked: true, disabled: true)
      expect(languages_page).to have_field("available_languages_ja", checked: false)

      expect { languages_page.save }
        .to change { Setting.find_by(name: "available_languages").value }
        .from(%w[de en])
        .to(%w[de en fr])
    end
  end

  context "when available languages setting is not writable (set by env var)", :settings_reset do
    it "disables the save button and does not change the available languages setting", with_env: {
      OPENPROJECT_AVAILABLE__LANGUAGES: "de en",
      OPENPROJECT_DEFAULT_LANGUAGE: "fr"
    } do
      reset(:available_languages)
      reset(:default_language)
      expect(Setting.available_languages_writable?).to be false

      languages_page.visit!

      expect(languages_page).to have_field("available_languages_de", checked: true, disabled: true)
      expect(languages_page).to have_field("available_languages_en", checked: true, disabled: true)
      expect(languages_page).to have_field("available_languages_fr", checked: true, disabled: true)
      expect(languages_page).to have_field("available_languages_ja", checked: false, disabled: true)

      expect(page).to have_button("Save", disabled: true)

      expect(Setting.where(name: "available_languages")).not_to exist
    end
  end
end
