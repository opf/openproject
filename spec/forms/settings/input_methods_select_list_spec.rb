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

RSpec.describe Settings::InputMethods, "#select_list", :aggregate_failures, :settings_reset, type: :forms do
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

  shared_examples "handling explicit :values param" do
    let(:params) { { values: } }

    context "with an Array of Strings" do
      let(:values) { ["one", "two"] }

      it "renders the select, using localized option text" do
        expect(rendered_form).to have_select "Ultimate answer" do |select|
          expect(select).to have_selector :option, count: 2
          expect(select).to have_selector :option, text: "One"
          expect(select).to have_selector :option, text: "Two"
        end
      end
    end

    context "with an Array of Arrays" do
      let(:values) { [["Uno", "one"], ["Duo", "two"]] }

      it "renders the select, using 'firsts' as option text" do
        expect(rendered_form).to have_select "Ultimate answer" do |select|
          expect(select).to have_selector :option, count: 2
          expect(select).to have_selector :option, text: "Uno"
          expect(select).to have_selector :option, text: "Duo"
        end
      end
    end

    context "with an Array of Arrays, including additional arguments Hash" do
      let(:values) do
        [
          ["Uno", "one", { data: { controller: "numero-uno" } }],
          ["Duo", "two", { aria: { description: "NUMBER TWO" } }]
        ]
      end

      it "renders the select, using 'firsts' as option text and applying HTML attributes" do
        expect(rendered_form).to have_select "Ultimate answer" do |select|
          expect(select).to have_selector :option, count: 2
          expect(select).to have_selector :option, text: "Uno" do |option|
            expect(option["data-controller"]).to eq "numero-uno"
          end
          expect(select).to have_selector :option, text: "Duo" do |option|
            expect(option["aria-description"]).to eq "NUMBER TWO"
          end
        end
      end
    end
  end

  context "with a block argument" do
    subject(:rendered_form) do
      vc_render_inline_settings_form do |settings_form|
        settings_form.select_list(name: :ultimate_answer, **params) do |select|
          select.option(label: "Custom label", value: "Custom value")
        end
      end

      page
    end

    it "renders the select, using specified :label" do
      expect(rendered_form).to have_select "Ultimate answer" do |select|
        expect(select).to have_selector :option, count: 1
        expect(select).to have_selector :option, text: "Custom label"
      end
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
        settings_form.select_list(name: :ultimate_answer, **params)
      end

      page
    end

    context "when allowed values are specified for Setting" do
      it "raises an ArgumentError" do
        expect { rendered_form }.to raise_error(ArgumentError, /You must supply a values: keyword argument/)
      end

      it_behaves_like "handling explicit :values param"
    end

    context "when Setting has allowed values" do
      let(:allowed) { %i[one two three] }

      it "renders the select, using localized option text" do
        expect(rendered_form).to have_select "Ultimate answer" do |select|
          expect(select).to have_selector :option, count: 3
          expect(select).to have_selector :option, text: "One"
          expect(select).to have_selector :option, text: "Two"
          expect(select).to have_selector :option, text: "Three"
        end
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
