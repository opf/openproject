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

require "spec_helper"
require "ostruct"

RSpec.describe SettingsHelper do
  include Capybara::RSpecMatchers

  let(:options) { { class: "custom-class" } }

  before do
    allow(Setting)
      .to receive(:host_name_writable?)
            .and_return true

    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with("setting_field_a").and_return("Field A")
    allow(I18n).to receive(:t).with("setting_field_b").and_return("Field B")
    allow(I18n).to receive(:t).with("setting_field").and_return("Field")
  end

  shared_examples_for "field disabled if non writable" do
    context "when the setting is writable" do
      it "is enabled" do
        expect(output)
          .to have_field "settings_host_name", disabled: false
      end
    end

    context "when the setting isn`t writable" do
      before do
        allow(Setting)
          .to receive(:host_name_writable?)
                .and_return false
      end

      it "is disabled" do
        expect(output)
          .to have_field "settings_host_name", disabled: true
      end
    end
  end

  describe "#setting_select" do
    subject(:output) do
      helper.setting_select :host_name, [["Popsickle", "1"], ["Jello", "2"], ["Ice Cream", "3"]], options
    end

    before do
      allow(Setting).to receive(:host_name).and_return("2")
    end

    it_behaves_like "labeled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "select-container"
    it_behaves_like "field disabled if non writable"

    it "outputs element" do
      expect(output).to have_css "select.form--select > option", count: 3
      expect(output).to have_select "settings_host_name", selected: "Jello"
    end
  end

  describe "#setting_multiselect" do
    subject(:output) do
      helper.setting_multiselect :host_name, [["Popsickle", "1"], ["Jello", "2"], ["Ice Cream", "3"]], options
    end

    before do
      allow(Setting).to receive(:host_name).at_least(:once).and_return("1")
    end

    it_behaves_like "wrapped in container" do
      let(:container_count) { 3 }
    end

    it "has checkboxes wrapped in checkbox-container" do
      expect(output).to have_css "span.form--check-box-container", count: 3
    end

    it "has three labels" do
      expect(output).to have_css "label.form--label-with-check-box", count: 3
    end

    it "outputs element" do
      expect(output).to have_css 'input[type="checkbox"].form--check-box', count: 3
    end

    context "when the setting isn`t writable" do
      before do
        allow(Setting)
          .to receive(:host_name_writable?)
                .and_return false
      end

      it "is disabled and has no hidden field" do
        expect(output).to have_no_css 'input[type="hidden"][value=""]', visible: :all
        expect(output).to have_css 'input[type="checkbox"][disabled="disabled"].form--check-box', count: 3
      end
    end
  end

  describe "#setting_text_field" do
    subject(:output) do
      helper.setting_text_field :host_name, options
    end

    before do
      allow(Setting).to receive(:host_name).and_return("important value")
    end

    it_behaves_like "labeled by default"
    it_behaves_like "wrapped in field-container by default"
    it_behaves_like "wrapped in container", "text-field-container"
    it_behaves_like "field disabled if non writable"

    it "outputs element" do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field"
          id="settings_host_name" name="settings[host_name]" type="text" value="important value" />
      }).at_path("input")
    end
  end

  describe "#setting_label" do
    subject(:output) do
      helper.setting_label :host_name
    end

    it_behaves_like "labeled"
    it_behaves_like "not wrapped in container"
  end
end
