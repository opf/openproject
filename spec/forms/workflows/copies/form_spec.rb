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
#
require "spec_helper"

RSpec.describe Workflows::Copies::Form, type: :forms do
  include_context "with rendered form"

  let(:model) { false }
  let(:params) { { source_variant:, source_role:, other_variants:, all_roles: } }
  let(:source_variant) { create(:type).default_variant }
  let(:other_variants) { create_list(:type, 4).map(&:default_variant) }
  let(:all_roles) { create_list(:project_role, 4) }

  # TODO: Remove with type_variants feature flag
  shared_examples "a copy form with conditional fields" do |another_type_at_first:|
    it "renders radio buttons to choose the mode" do
      expect(page).to have_field("Copy to another type", checked: another_type_at_first)
      expect(page).to have_field("Copy to other roles", checked: !another_type_at_first)
    end

    it "renders the Target types autocompleter" do
      data_attributes = "[data-test-selector=\"target_types_autocomplete\"][data-multiple=\"true\"]"
      expect(page).to have_css "opce-autocompleter#{data_attributes}", visible: another_type_at_first do |autocompleter|
        options_text = JSON.parse(autocompleter["data-items"]).map { |item| item["name"] }
        expect(options_text).to match_array(other_variants.map(&:composite_name))
      end
    end

    it "renders the Source role select list" do
      required = another_type_at_first
      disabled = visible = !another_type_at_first
      expect(page).to have_select "Source role", required:, disabled:, visible: do |select|
        options_text = select.all("option", visible: !another_type_at_first).map(&:text)
        expect(options_text).to match_array(all_roles.map(&:name))
      end
    end

    it "renders the Target roles autocompleter" do
      data_attributes = "[data-test-selector=\"target_roles_autocomplete\"][data-multiple=\"true\"]"
      expect(page).to have_css "opce-autocompleter#{data_attributes}", visible: !another_type_at_first do |autocompleter|
        options_text = JSON.parse(autocompleter["data-items"]).map { |item| item["name"] }
        expect(options_text).to match_array(all_roles.map(&:name))
      end
    end
  end

  describe "when the source role is not specified" do
    let(:source_role) { nil }

    it_behaves_like "a copy form with conditional fields", another_type_at_first: true
  end

  describe "when the source role is specified" do
    let(:source_role) { all_roles.sample }

    it_behaves_like "a copy form with conditional fields", another_type_at_first: false

    it "renders the Source role select list with read-only source" do
      expect(page).to have_select "Source role", disabled: true do |select|
        selected_option_text = select.all("option[selected=selected]").map(&:text)
        expect(selected_option_text).to contain_exactly(source_role.name)
      end
    end
  end

  describe "with the type_variants feature flag enabled", with_flag: { type_variants: true } do
    let(:source_role) { all_roles.sample }

    it "does not render the mode radio buttons" do
      expect(page).to have_no_field("Copy to another type")
      expect(page).to have_no_field("Copy to other roles")
    end

    it "does not render the Target types autocompleter" do
      expect(page).to have_no_css "opce-autocompleter[data-test-selector=\"target_types_autocomplete\"]"
    end

    it "does not render the Source role select list" do
      expect(page).to have_no_select "Source role"
    end

    it "renders the Target roles autocompleter" do
      data_attributes = "[data-test-selector=\"target_roles_autocomplete\"][data-multiple=\"true\"]"
      expect(page).to have_css "opce-autocompleter#{data_attributes}" do |autocompleter|
        options_text = JSON.parse(autocompleter["data-items"]).map { |item| item["name"] }
        expect(options_text).to match_array(all_roles.map(&:name))
      end
    end
  end
end
