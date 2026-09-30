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

RSpec.describe Settings::InputMethods, "#rich_text_area", :aggregate_failures, :settings_reset, type: :forms do
  include_context "with rendered inline settings form"
  include_context "with locale for testing"

  let(:translations) { { setting_ultimate_answer: "Ultimate answer" } }
  let(:name) { "ultimate_answer" }
  let(:format) { :string }
  let(:default) { nil }

  before do
    Settings::Definition.add(name, default:, format:)
    Setting.create!(name:, value: "")
  end

  subject(:rendered_form) do
    vc_render_inline_settings_form do |settings_form|
      settings_form.rich_text_area(name: :ultimate_answer, rich_text_options: {})
    end

    page
  end

  it "renders the backing text area" do
    expect(rendered_form).to have_field "Ultimate answer", type: "textarea", visible: :hidden
  end

  it "renders the augmented text area" do
    expect(rendered_form).to have_element "opce-ckeditor-augmented-textarea",
                                          "data-text-area-id": "ultimate_answer".to_json
  end
end
