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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Field rules administration" do # rubocop:disable RSpec/DescribeClass
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }

  current_user { admin }

  it "creates a rule set with a required description and a hidden category" do
    visit new_admin_field_rule_set_path
    fill_in "rule_set_name", with: "Bug rules"
    check "rule_set_description_required"
    check "rule_set_category_hidden"
    click_button "Create"

    expect(page).to have_text("Successful creation.")
    rule_set = FieldRuleSet.find_by!(name: "Bug rules")
    expect(rule_set.rule_for("description")).to be_required
    expect(rule_set.rule_for("category")).to be_hidden
    expect(rule_set.rules.size).to eq 2
  end

  it "shows validation errors for impossible combinations" do
    visit new_admin_field_rule_set_path
    fill_in "rule_set_name", with: "Broken"
    check "rule_set_description_hidden"
    check "rule_set_description_required"
    click_button "Create"

    expect(page).to have_text("cannot be combined with hidden")
    expect(FieldRuleSet.exists?(name: "Broken")).to be false
  end

  context "with an existing rule set" do
    let!(:rule_set) { create(:field_rule_set, name: "Base", rule_attributes: [{ field_key: "description", required: true }]) }

    it "clones, deactivates and reactivates but never deletes" do
      visit admin_field_rule_sets_path
      expect(page).to have_no_button("Delete")

      click_button "Clone", match: :first
      expect(page).to have_css("tr", text: "Base - Custom")

      within("tr", text: /\ABase\s/) { click_button "Deactivate" }
      expect(rule_set.reload).not_to be_active

      within("tr", text: /\ABase\s/) { click_button "Activate" }
      expect(rule_set.reload).to be_active
    end

    context "when used by a project" do
      let!(:project) { create(:project, types: [bug]) }

      before do
        scheme = create(:field_rule_scheme, mapping: { bug => rule_set })
        FieldRules::SchemeService.assign(project, scheme)
      end

      it "asks for confirmation before saving a shared rule set" do
        visit edit_admin_field_rule_set_path(rule_set)
        uncheck "rule_set_description_required"
        click_button "Save"

        expect(page).to have_text("1 project(s)")
        expect(rule_set.reload.rule_for("description")).to be_required

        click_button "Confirm"
        expect(page).to have_text("Successful update.")
        expect(rule_set.reload.rules).to be_empty
      end
    end
  end

  it "creates a scheme mapping a type to a rule set" do
    rule_set = create(:field_rule_set, name: "Bug rules")
    visit new_admin_field_rule_scheme_path
    fill_in "scheme_name", with: "Software"
    select rule_set.name, from: "scheme_types_#{bug.id}"
    click_button "Create"

    expect(page).to have_text("Successful creation.")
    expect(FieldRuleScheme.find_by!(name: "Software").rule_set_for(bug.id)).to eq rule_set
  end

  context "as a non-admin" do
    current_user { create(:user) }

    it "is forbidden" do
      visit admin_field_rule_sets_path
      expect(page).to have_text("You are not authorized")
    end
  end
end
