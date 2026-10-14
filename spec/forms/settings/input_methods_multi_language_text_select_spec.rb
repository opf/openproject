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

require "rails_helper"

RSpec.describe Settings::InputMethods, "#multi_language_text_select", :aggregate_failures, :settings_reset,
               type: :forms, with_settings: { available_languages: %w[en de] } do
  include_context "with rendered inline settings form"
  include_context "with locale for testing"

  let(:translations) { { setting_ultimate_answer: "Ultimate answer" } }
  let(:name) { "ultimate_answer" }
  let(:stimulus_target) { :"data-admin--multi-lang-text-setting-target" }
  let(:form_arguments) { { url: "/foo", scope: :settings } }

  before do
    Settings::Definition.add(name, default: {}, format: :hash)
    Setting[name] = { "en" => "Forty-two", "de" => "Zweiundvierzig" }
  end

  subject(:rendered_form) do
    vc_render_inline_settings_form do |settings_form|
      settings_form.multi_language_text_select(name: :ultimate_answer, current_language: "en")
    end

    page
  end

  it "renders a language select with the current language selected" do
    expect(rendered_form).to have_select "Ultimate answer", selected: "English" do |select|
      expect(select["name"]).to eq "settings[ultimate_answer_lang]"
    end
  end

  it "renders the text of the current language in the editor and every language in hidden fields" do
    expect(rendered_form).to have_field "settings[ultimate_answer][en]", type: :textarea, with: "Forty-two", visible: :all
    expect(rendered_form).to have_field "settings[ultimate_answer][en]", type: :hidden, with: "Forty-two"
    expect(rendered_form).to have_field "settings[ultimate_answer][de]", type: :hidden, with: "Zweiundvierzig"
  end

  it "wires the inputs to the multi language text setting controller" do
    expect(rendered_form).to have_element :div, "data-controller": "admin--multi-lang-text-setting" do |wrapper|
      expect(wrapper).to have_element :select, id: "lang-for-ultimate_answer", stimulus_target => "select"

      expect(wrapper).to have_element :input, type: "hidden", name: "settings[ultimate_answer][en]",
                                              stimulus_target => "langFor", "data-lang": "en", visible: :all
      expect(wrapper).to have_element :input, type: "hidden", name: "settings[ultimate_answer][de]",
                                              stimulus_target => "langFor", "data-lang": "de", visible: :all

      expect(wrapper).to have_element :textarea, id: "settings_ultimate_answer_en", stimulus_target => "textArea", visible: :all
      expect(wrapper).to have_element "opce-ckeditor-augmented-textarea",
                                      "data-text-area-id": '"settings_ultimate_answer_en"'
    end
  end
end
