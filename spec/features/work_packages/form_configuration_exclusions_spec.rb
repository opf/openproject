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

RSpec.describe "Work package show with a linked form configuration", :js,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  shared_let(:kept_field) { create(:issue_custom_field, :integer, name: "KeptNumber", is_for_all: true) }
  shared_let(:excluded_field) { create(:issue_custom_field, :integer, name: "ExcludedNumber", is_for_all: true) }
  shared_let(:solo_field) { create(:issue_custom_field, :integer, name: "SoloNumber", is_for_all: true) }

  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

  # The type owning the configuration: two groups of custom fields, one of which the leaf
  # ends up emptying completely.
  let(:owner) do
    create(:type).tap do |type|
      type.attribute_groups = [
        ["Numbers", [kept_field.attribute_name, excluded_field.attribute_name]],
        ["Solo", [solo_field.attribute_name]],
        ["People", %w[assignee]]
      ]
      type.custom_field_ids = [kept_field.id, excluded_field.id, solo_field.id]
      type.save!
    end
  end

  let(:leaf) { create(:type) }
  let(:project) { create(:project, types: [owner, leaf]) }

  let(:work_package) do
    create(:work_package,
           project:,
           type: leaf,
           custom_values: {
             kept_field.id => 1,
             excluded_field.id => 2,
             solo_field.id => 3
           })
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  before { login_as(admin) }

  # Both directions assert on the same selector on purpose. The page object's
  # #expect_hidden_field and #expect_no_attribute build a different (or differently cased)
  # selector than #expect_attributes, so they hold whether or not the field rendered — a
  # negative assertion that can never fail is worse than none.
  def field_selector(field)
    ".inline-edit--container.#{field.attribute_name(:camel_case)}"
  end

  def expect_field(field, value)
    expect(page).to have_css(field_selector(field), text: value)
  end

  def expect_no_field(field)
    expect(page).to have_no_css(field_selector(field))
  end

  def expect_no_section(name)
    expect(page).to have_no_css(".attributes-group[data-group-name='#{name}']")
  end

  context "when linked without exclusions" do
    before do
      create(:type_configuration_link, type: leaf, source: owner, aspect:)
    end

    it "renders the owning type's groups and fields" do
      wp_page.visit!
      wp_page.ensure_page_loaded

      wp_page.expect_group("Numbers") do
        expect_field(kept_field, "1")
        expect_field(excluded_field, "2")
      end

      wp_page.expect_group("Solo") do
        expect_field(solo_field, "3")
      end

      wp_page.expect_group("People")
    end
  end

  context "when the link excludes a field and empties a group" do
    before do
      create(:type_configuration_link, type: leaf, source: owner, aspect:,
                                       excluded_elements: [excluded_field.attribute_name,
                                                           solo_field.attribute_name])
    end

    it "renders only what remains, dropping the emptied group" do
      wp_page.visit!
      wp_page.ensure_page_loaded

      # The positive assertion first: it proves the form has finished rendering this region,
      # so the absences below are real rather than a not-yet-rendered page.
      wp_page.expect_group("Numbers") do
        expect_field(kept_field, "1")
      end

      expect_no_field(excluded_field)
      expect_no_section("Solo")
      expect_no_field(solo_field)
    end

    it "keeps rendering everything on the owning type itself" do
      owner_work_package = create(:work_package,
                                  project:,
                                  type: owner,
                                  custom_values: {
                                    kept_field.id => 1,
                                    excluded_field.id => 2,
                                    solo_field.id => 3
                                  })
      owner_page = Pages::FullWorkPackage.new(owner_work_package)

      owner_page.visit!
      owner_page.ensure_page_loaded

      owner_page.expect_group("Numbers") do
        expect_field(excluded_field, "2")
      end
      owner_page.expect_group("Solo") do
        expect_field(solo_field, "3")
      end
    end
  end

  context "when the exclusions accumulate over a chain" do
    let(:middle) { create(:type) }

    before do
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: [excluded_field.attribute_name])
      create(:type_configuration_link, type: leaf, source: middle, aspect:,
                                       excluded_elements: [solo_field.attribute_name])
    end

    it "renders the leaf without either ancestor's excluded fields" do
      wp_page.visit!
      wp_page.ensure_page_loaded

      wp_page.expect_group("Numbers") do
        expect_field(kept_field, "1")
      end

      expect_no_field(excluded_field)
      expect_no_section("Solo")
    end
  end

  context "with the flag off", with_flag: { type_variants: false } do
    before do
      leaf.attribute_groups = [["Own", [kept_field.attribute_name]]]
      leaf.custom_field_ids = [kept_field.id]
      leaf.save!

      create(:type_configuration_link, type: leaf, source: owner, aspect:,
                                       excluded_elements: [kept_field.attribute_name])
    end

    it "ignores the link and renders the type's own configuration" do
      wp_page.visit!
      wp_page.ensure_page_loaded

      wp_page.expect_group("Own") do
        expect_field(kept_field, "1")
      end
      expect_no_section("Numbers")
    end
  end
end
