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

RSpec.describe Settings::InputMethods, "#text_field", :aggregate_failures, :settings_reset, type: :forms do
  include_context "with rendered inline settings form"
  include_context "with locale for testing"

  let(:translations) { { setting_ultimate_answer: "Ultimate answer" } }
  let(:name) { "ultimate_answer" }
  let(:format) { :string }
  let(:default) { nil }
  let(:writable) { true }
  let(:secret) { false }
  let(:stored_value) { "" }
  let(:field_options) { {} }

  before do
    Settings::Definition.add(name, default:, format:, writable:, secret:)
    Setting[name] = stored_value if writable
  end

  subject(:rendered_form) do
    vc_render_inline_settings_form do |settings_form|
      settings_form.text_field(name: :ultimate_answer, **field_options)
    end

    page
  end

  it "renders the text field" do
    expect(rendered_form).to have_field "Ultimate answer", type: :text
  end

  context "with a stored value" do
    let(:stored_value) { "42" }

    it "renders the value" do
      expect(rendered_form).to have_field "Ultimate answer", type: :text, with: "42"
    end
  end

  context "with a secret setting" do
    let(:secret) { true }

    context "with a stored value" do
      let(:stored_value) { "s3cr3t" }

      it "renders a password field with the placeholder instead of the value" do
        expect(rendered_form).to have_field "Ultimate answer",
                                            type: :password,
                                            with: Settings::Definition::SECRET_PLACEHOLDER do |field|
          expect(field["autocomplete"]).to eq "off"
        end
        expect(rendered_form.native.to_html).not_to include("s3cr3t")
      end
    end

    context "without a stored value" do
      it "renders an empty password field" do
        expect(rendered_form).to have_field "Ultimate answer", type: :password do |field|
          expect(field["value"]).to be_nil
        end
      end
    end

    context "when the caller passes a value" do
      let(:stored_value) { "s3cr3t" }
      let(:field_options) { { value: "s3cr3t" } }

      it "does not render the passed value" do
        expect(rendered_form).to have_field "Ultimate answer",
                                            type: :password,
                                            with: Settings::Definition::SECRET_PLACEHOLDER
        expect(rendered_form.native.to_html).not_to include("s3cr3t")
      end
    end

    context "when the setting is not writable" do
      let(:writable) { false }
      let(:default) { "s3cr3t" }

      it "renders a disabled password field without the value" do
        expect(rendered_form).to have_field "Ultimate answer",
                                            type: :password,
                                            disabled: true,
                                            with: Settings::Definition::SECRET_PLACEHOLDER
        expect(rendered_form.native.to_html).not_to include("s3cr3t")
      end
    end
  end
end
