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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Admin::Settings::LanguagesSettingsForm, type: :forms do
  include_context "with rendered form"

  let(:form_arguments) { { url: "/foo", model: false, scope: :settings } }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "renders", :aggregate_failures do
    expect(rendered_form).to have_field "settings[available_languages][]", type: :hidden, with: "en"

    expect(rendered_form).to have_field "English", type: :checkbox,
                                                   disabled: true,
                                                   fieldset: "Available languages" do |field|
      expect(field["name"]).to eq "settings[available_languages][]"
      expect(field["value"]).to eq "en"
    end
    expect(rendered_form).to have_element :label, text: "English", lang: "en"

    expect(rendered_form).to have_field "Español", type: :checkbox, fieldset: "Available languages"
    expect(rendered_form).to have_element :label, text: "Español", lang: "es"

    expect(rendered_form).to have_field "Українська", type: :checkbox, fieldset: "Available languages"
    expect(rendered_form).to have_element :label, text: "Українська", lang: "uk"

    expect(rendered_form).to have_field "简体中文", type: :checkbox, fieldset: "Available languages"
    expect(rendered_form).to have_element :label, text: "简体中文", lang: "zh-CN"
  end
end
