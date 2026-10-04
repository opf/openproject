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

RSpec.describe Settings::InputMethods, "#radio_button_group", :aggregate_failures, :settings_reset, type: :forms do
  include_context "with rendered inline settings form"
  include_context "with locale for testing"

  let(:translations) do
    {
      setting_ultimate_answer: "Ultimate answer",
      setting_ultimate_answer_one: "One",
      setting_ultimate_answer_two: "Two",
      setting_ultimate_answer_three: "Three"
    }
  end
  let(:name) { "ultimate_answer" }
  let(:format) { :symbol }
  let(:default) { nil }
  let(:allowed) { nil }
  let(:params) { {} }

  before do
    Settings::Definition.add(name, default:, format:, allowed:)
    Setting.create!(name:, value: "")
  end

  shared_examples "rendering fieldset" do
    it "renders the fieldset" do
      expect(rendered_form).to have_selector :fieldset, "Ultimate answer"
    end
  end

  shared_examples "handling explicit :values param" do
    let(:params) { { values: } }

    context "with an Array of Strings" do
      let(:values) { ["one", "two"] }

      include_examples "rendering fieldset"

      it "renders the radio buttons, using localized label text" do
        expect(rendered_form).to have_field count: 2, type: :radio, fieldset: "Ultimate answer"
        expect(rendered_form).to have_field "One", type: :radio
        expect(rendered_form).to have_field "Two", type: :radio
      end
    end

    context "with an Array of Arrays" do
      let(:values) { [["Uno", "one"], ["Duo", "two"]] }

      include_examples "rendering fieldset"

      it "renders the radio buttons, using 'firsts' as label text" do
        expect(rendered_form).to have_field count: 2, type: :radio, fieldset: "Ultimate answer"
        expect(rendered_form).to have_field "Uno", type: :radio
        expect(rendered_form).to have_field "Duo", type: :radio
      end
    end

    context "with an Array of Arrays, including additional arguments Hash" do
      let(:values) do
        [
          ["Uno", "one", { data: { controller: "numero-uno" } }],
          ["Duo", "two", { aria: { description: "NUMBER TWO" } }]
        ]
      end

      include_examples "rendering fieldset"

      it "renders the radio buttons, using 'firsts' as label text and applying HTML attributes" do
        expect(rendered_form).to have_field count: 2, type: :radio, fieldset: "Ultimate answer"
        expect(rendered_form).to have_field "Uno", type: :radio do |field|
          expect(field["data-controller"]).to eq "numero-uno"
        end
        expect(rendered_form).to have_field "Duo", type: :radio do |field|
          expect(field["aria-description"]).to eq "NUMBER TWO"
        end
      end
    end
  end

  context "with a block argument" do
    subject(:rendered_form) do
      vc_render_inline_settings_form do |settings_form|
        settings_form.radio_button_group(name: :ultimate_answer, **params) do |group|
          group.radio_button(label: "Custom label 1", value: "Custom value 1")
          group.radio_button(label: "Custom label 2", value: "Custom value 2")
        end
      end

      page
    end

    include_examples "rendering fieldset"

    it "renders the radio buttons, using specified :label" do
      expect(rendered_form).to have_field count: 2, type: :radio, fieldset: "Ultimate answer"
      expect(rendered_form).to have_field "Custom label 1", type: :radio
      expect(rendered_form).to have_field "Custom label 2", type: :radio
    end

    context "with explicit :values param" do
      let(:params) { { values: } }
      let(:values) { ["one", "two"] }

      it "raises an ArgumentError" do
        expect { rendered_form }.to raise_error(ArgumentError, /Pass a block or values: keyword argument. Not both./)
      end
    end
  end

  context "without a block argument" do
    subject(:rendered_form) do
      vc_render_inline_settings_form do |settings_form|
        settings_form.radio_button_group(name: :ultimate_answer, **params)
      end

      page
    end

    context "when Setting has no specified allowed values" do
      it "raises an ArgumentError" do
        expect { rendered_form }.to raise_error(ArgumentError, /You must supply a values: keyword argument/)
      end

      it_behaves_like "handling explicit :values param"
    end

    context "when Setting has allowed values" do
      let(:allowed) { %i[one two three] }

      include_examples "rendering fieldset"

      it "renders the radio buttons, using localized label text" do
        expect(rendered_form).to have_field count: 3, type: :radio, fieldset: "Ultimate answer"
        expect(rendered_form).to have_field "One", type: :radio
        expect(rendered_form).to have_field "Two", type: :radio
        expect(rendered_form).to have_field "Three", type: :radio
      end

      it_behaves_like "handling explicit :values param"

      context "when translation does not exist for an allowed value" do
        let(:allowed) { %i[four] }

        it "raises an I18n error" do # TODO: verify behavior
          expect do
            rendered_form
          end.to raise_error(I18n::MissingTranslationData, /Translation missing: mo.setting_ultimate_answer_four/)
        end
      end
    end
  end
end
