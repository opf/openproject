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

require "rails_helper"

RSpec.describe Settings::PageSectionForm, type: :forms do
  include ViewComponent::TestHelpers

  let(:settings_page) { Settings::Pages.fetch(:general) }

  def render_section(section, form_hook: nil)
    render_in_view_context(section, form_hook) do |section, form_hook|
      primer_form_with(url: "/foo", model: false, scope: :settings) do |f|
        render(Settings::PageSectionForm.new(f, section:, form_hook:))
      end
    end
    page
  end

  context "for the general section of the general page" do
    subject(:rendered_form) { render_section(settings_page.sections.first) }

    it "derives the inputs from the setting definitions", :aggregate_failures do # rubocop:disable RSpec/ExampleLength
      expect(rendered_form).to have_field "Application title", type: :text do |field|
        expect(field["name"]).to eq "settings[app_title]"
      end

      expect(rendered_form).to have_field "Objects per page options", type: :text do |field|
        expect(field["name"]).to eq "settings[per_page_options]"
      end

      expect(rendered_form).to have_field "Days displayed on project activity", type: :number,
                                                                                accessible_description: "days" do |field|
        expect(field["name"]).to eq "settings[activity_days_default]"
      end

      expect(rendered_form).to have_field "Host name", type: :text do |field|
        expect(field["name"]).to eq "settings[host_name]"
      end

      expect(rendered_form).to have_field "Cache formatted text", type: :checkbox do |field|
        expect(field["name"]).to eq "settings[cache_formatted_text]"
      end

      expect(rendered_form).to have_field "Allowed link protocols", type: :textarea do |field|
        expect(field["name"]).to eq "settings[allowed_link_protocols]"
      end

      expect(rendered_form).to have_field "Enable Feeds", type: :checkbox do |field|
        expect(field["name"]).to eq "settings[feeds_enabled]"
      end

      expect(rendered_form).to have_field "Feed content limit", type: :number do |field|
        expect(field["name"]).to eq "settings[feeds_limit]"
      end

      expect(rendered_form).to have_field "Max size of text files displayed inline", type: :number,
                                                                                     accessible_description: "kB" do |field|
        expect(field["name"]).to eq "settings[file_max_size_displayed]"
      end

      expect(rendered_form).to have_field "Max number of diff lines displayed", type: :number do |field|
        expect(field["name"]).to eq "settings[diff_max_lines_displayed]"
      end
    end

    it "renders captions given as lambdas in the view context" do
      expect(rendered_form).to have_text "#{I18n.t(:label_example)}: test.host"
      expect(rendered_form).to have_css "code", text: "tel"
    end
  end

  context "for the welcome section of the general page" do
    subject(:rendered_form) { render_section(settings_page.sections.second) }

    it "renders the inputs", :aggregate_failures do
      expect(rendered_form).to have_field "Welcome block title", type: :text do |field|
        expect(field["name"]).to eq "settings[welcome_title]"
      end

      expect(rendered_form).to have_field "Welcome block text", type: :textarea, visible: :hidden do |field|
        expect(field["name"]).to eq "settings[welcome_text]"
      end

      expect(rendered_form).to have_field "Display welcome block on homescreen", type: :checkbox do |field|
        expect(field["name"]).to eq "settings[welcome_on_homescreen]"
      end
    end
  end

  context "for the languages page" do
    subject(:rendered_form) { render_section(Settings::Pages.fetch(:languages).sections.first) }

    it "renders the available languages with the default one checked and disabled", :aggregate_failures do
      expect(rendered_form).to have_field "settings[available_languages][]", type: :hidden, with: ""
      expect(rendered_form).to have_field "English (default)", type: :checkbox, checked: true, disabled: true,
                                                               fieldset: "Available languages"
      expect(rendered_form).to have_element :label, text: "Español", lang: "es"
      expect(rendered_form).to have_element :label, text: "简体中文", lang: "zh-CN"
    end
  end

  context "for the date format page" do
    subject(:rendered_form) { render_section(Settings::Pages.fetch(:date_format).sections.first) }

    it "renders selects with the values given as hints", :aggregate_failures do
      expect(rendered_form).to have_select "Time", with_options: ["Based on user's language", Time.current.strftime("%H:%M")]
      expect(rendered_form).to have_select "Week starts on", with_options: %w[Monday Saturday Sunday]
    end
  end

  context "for the external links page" do
    subject(:rendered_form) do
      render_section(Settings::Pages.fetch(:external_links).sections.first,
                     form_hook: :component_admin_settings_external_redirect)
    end

    it "renders the captions from the translation keys given as hints" do
      expect(rendered_form).to have_field "Capture external links", type: :checkbox,
                                                                    disabled: :all,
                                                                    accessible_description: /redirect through a warning page/
    end

    it "calls the form hook" do
      allow(OpenProject::Hook).to receive(:call_hook).and_call_original

      rendered_form

      expect(OpenProject::Hook)
        .to have_received(:call_hook)
        .with(:component_admin_settings_external_redirect, hash_including(:form))
    end
  end
end
