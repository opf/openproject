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

RSpec.describe OpenProject::Common::InplaceEditFieldDialogComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:user) { build_stubbed(:admin) }
  let(:comments_enabled) { false }
  let(:writable) { true }

  current_user { user }

  def render_dialog
    render_inline(described_class.new(model: project.reload,
                                      attribute: custom_field.attribute_name.to_sym,
                                      system_arguments: { writable: }))
  end

  def expect_value
    expect(page).to value_matcher
  end

  shared_examples "custom field comments and read-only values" do
    before do
      initial_values.each do |value|
        create(:custom_value, customized: project, custom_field:, value:)
      end
    end

    it "omits the comment input when comments are disabled" do
      render_dialog

      expect(page).to have_no_field("Comment")
    end

    context "with comments enabled" do
      let(:comments_enabled) { true }

      it "renders blank and saved comments" do
        render_dialog
        expect(page).to have_field("Comment", with: "")

        create(:custom_comment, custom_field:, customized: project, text: "bar")
        render_dialog
        expect(page).to have_field("Comment", with: "bar")
      end

      context "when the user has view permission only" do
        let(:writable) { false }
        let(:user) do
          create(:user, member_with_permissions: { project => %i[view_work_packages view_project_attributes] })
        end

        it "renders the value and comment without editable fields or save controls" do
          create(:custom_comment, custom_field:, customized: project, text: "baz")
          render_dialog

          expect_value
          expect(page).to have_no_field(custom_field.name)
          expect(page).to have_no_field("Comment")
          expect(page).to have_no_test_selector("op-inplace-edit-field--form")
          expect(page).to have_text("Comment")
          expect(page).to have_text("baz")
          expect(page).to have_button(I18n.t(:button_close))
          expect(page).to have_no_button(I18n.t(:button_save))
        end
      end
    end
  end

  [
    [:boolean, true, "Yes"],
    [:string, "Foo", "Foo"],
    [:integer, 123, "123"],
    [:float, 123.456, "123.456"],
    [:date, "2024-01-01", "01/01/2024"],
    [:text, "Lorem\n\nipsum", "Lorem"]
  ].each do |format, value, display_value|
    context "with a #{format} custom field" do
      let(:custom_field) { create(:"#{format}_project_custom_field", projects: [project], has_comment: comments_enabled) }
      let(:initial_values) { [value] }
      let(:value_matcher) { have_text(display_value) }

      include_examples "custom field comments and read-only values"
    end
  end

  context "with a link custom field" do
    let(:custom_field) { create(:link_project_custom_field, projects: [project], has_comment: comments_enabled) }
    let(:initial_values) { ["https://www.openproject.org"] }
    let(:value_matcher) { have_link("https://www.openproject.org", href: "https://www.openproject.org") }

    include_examples "custom field comments and read-only values"
  end

  context "with a calculated_value custom field", with_ee: %i[calculated_values] do
    let(:custom_field) do
      create(:calculated_value_project_custom_field, projects: [project], has_comment: comments_enabled, formula: "117 * 2")
    end
    let(:initial_values) { [234] }
    let(:value_matcher) { have_text("234") }

    include_examples "custom field comments and read-only values"
  end

  [false, true].each do |multiple|
    context "with a #{multiple ? 'multi' : 'single'} list custom field" do
      let(:custom_field) do
        create(:list_project_custom_field, projects: [project], has_comment: comments_enabled, multi_value: multiple,
                                           possible_values: ["Option 1", "Option 2", "Option 3"])
      end
      let(:selected_options) { custom_field.custom_options.first(multiple ? 2 : 1) }
      let(:initial_values) { selected_options.pluck(:id) }
      let(:value_matcher) { have_text(selected_options.pluck(:value).join(", ")) }

      include_examples "custom field comments and read-only values"
    end

    context "with a #{multiple ? 'multi' : 'single'} version custom field" do
      let(:custom_field) do
        create(:version_project_custom_field, projects: [project], has_comment: comments_enabled, multi_value: multiple)
      end
      let(:versions) { create_list(:version, multiple ? 2 : 1, project:) }
      let(:initial_values) { versions.pluck(:id) }
      let(:value_matcher) { have_text(versions.pluck(:name).join(", ")) }

      include_examples "custom field comments and read-only values"
    end

    context "with a #{multiple ? 'multi' : 'single'} user custom field" do
      let(:custom_field) do
        create(:user_project_custom_field, projects: [project], has_comment: comments_enabled, multi_value: multiple)
      end
      let(:members) do
        create_list(:user, multiple ? 2 : 1, member_with_permissions: { project => %i[view_work_packages] })
      end
      let(:initial_values) { members.pluck(:id) }

      def expect_value
        principals = page.all("opce-principal").map { JSON.parse(it["data-principal"]) }
        expect(principals.pluck("id")).to eq(members.pluck(:id))
        expect(principals.pluck("name")).to eq(members.map(&:name))
        expect(page).to have_css("opce-principal[data-hide-name='false']", count: members.size)
      end

      include_examples "custom field comments and read-only values"
    end
  end
end
