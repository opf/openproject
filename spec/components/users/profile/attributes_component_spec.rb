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

RSpec.describe Users::Profile::AttributesComponent, type: :component do
  let(:component) { described_class.new(user:) }

  describe "render?" do
    subject { component.render? }

    context "when user has hide_mail = false in their preferences" do
      let(:user) { build(:user, preferences: { hide_mail: false }) }

      it { is_expected.to be(true) }
    end

    context "when user has hide_mail = true in their preferences" do
      let(:user) { build(:user, preferences: { hide_mail: true }) }

      it { is_expected.to be(false) }
    end

    context "when user has a custom field with a present value" do
      let(:custom_field) { create(:user_custom_field, :string) }
      let(:user) { build(:user, custom_values: [build(:custom_value, custom_field:, value: "Hello")]) }

      it { is_expected.to be(true) }
    end

    context "when user has a custom field with a blank value" do
      let(:custom_field) { create(:user_custom_field, :string) }
      let(:user) { build(:user, custom_values: [build(:custom_value, custom_field:, value: "  ")]) }

      it { is_expected.to be(false) }
    end

    context "when user has a non-visible custom field with a present value" do
      let(:custom_field) { create(:user_custom_field, :string, admin_only: true) }
      let(:user) { build(:user, custom_values: [build(:custom_value, custom_field:, value: "Hello")]) }

      it { is_expected.to be(false) }
    end
  end

  describe "Custom field" do
    let(:custom_field) { create(:user_custom_field, :string, admin_only:) }
    let(:custom_values) do
      [build(:custom_value, custom_field:, value: "Hello custom field")]
    end
    let(:admin_only) { false }
    let(:user) { build_stubbed(:user, custom_values:) }

    current_user { build(:admin) }

    before do
      render_inline(component)
    end

    it "renders the field" do
      expect(page).to have_text("Hello custom field")
    end

    context "when not visible" do
      let(:admin_only) { true }

      it "does not render the field" do
        expect(page).to have_no_text("Hello custom field")
      end
    end

    context "with multiple custom fields" do
      let(:list_custom_field) { create(:user_custom_field, :multi_list, admin_only:, name: "Ze list") }
      let(:text_custom_field) { create(:user_custom_field, :text, admin_only:, name: "A portrait") }
      let(:custom_values) do
        [
          build(:custom_value, custom_field: list_custom_field, value: list_custom_field.possible_values[0]),
          build(:custom_value, custom_field: list_custom_field, value: list_custom_field.possible_values[1]),
          build(:custom_value, custom_field: list_custom_field, value: list_custom_field.possible_values[2]),
          build(:custom_value, custom_field: text_custom_field, value: "This is **formatted** text.")
        ]
      end

      it "renders the fields correctly and sorted" do
        # correct render of formattable
        expect(page).to have_css("strong", text: "formatted")
        # correct render of multi select
        expect(page).to have_text("A, B, C")
        # alphabetical order
        items = page.all(:test_id, "user-custom-field")
        expect(items[0]).to have_text("A portrait")
        expect(items[1]).to have_text("Ze list")
      end
    end
  end
end
