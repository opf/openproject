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

RSpec.describe Admin::Settings::UsersSettings::UserConsentForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", scope: :settings } }

  it "renders", :aggregate_failures do
    expect(page).to have_field "Consent required", type: :checkbox, fieldset: "User Consent" do |field|
      expect(field["name"]).to eq "settings[consent_required]"
    end

    expect(page).to have_select "Consent information text", fieldset: "User Consent", selected: "English" do |field|
      expect(field["name"]).to eq "settings[consent_info_lang]"
    end

    expect(page).to have_field "Consent time", type: :checkbox, fieldset: "User Consent"

    expect(page).to have_field "Consent contact mail address",
                               type: :email,
                               fieldset: "User Consent",
                               accessible_description: I18n.t("consent.contact_mail_instructions") do |field|
      expect(field["name"]).to eq "settings[consent_decline_mail]"
    end
  end

  context "with consent texts in several languages",
          with_settings: { consent_info: { en: "Please consent.", de: "Bitte zustimmen." } } do
    it "renders the text of the current language in the editor and the others in hidden fields" do
      expect(page).to have_field "settings[consent_info][en]", type: :textarea, with: "Please consent.", visible: :all
      expect(page).to have_field "settings[consent_info][de]", type: :hidden, with: "Bitte zustimmen."
    end
  end

  context "with a consent contact mail address", with_settings: { consent_decline_mail: "privacy@example.com" } do
    it "renders the stored address" do
      expect(page).to have_field "Consent contact mail address", with: "privacy@example.com"
    end
  end

  describe "consent time checkbox" do
    it "is submitted outside of the settings scope" do
      expect(page).to have_field "Consent time" do |field|
        expect(field["name"]).to eq "toggle_consent_time"
      end
    end

    context "when consent has never been updated", with_settings: { consent_time: nil } do
      it "is checked and shows that there was no update yet" do
        expect(page).to have_checked_field "Consent time"
        expect(page).to have_element :strong, text: "Last update of consent: Never"
      end
    end

    context "when consent has been updated before", with_settings: { consent_time: Time.zone.local(2026, 3, 14, 15, 9) } do
      it "is unchecked and shows the time of the last update" do
        expect(page).to have_unchecked_field "Consent time"
        expect(page).to have_element :strong, text: "Last update of consent: 03/14/2026 03:09 PM"
      end
    end
  end
end
