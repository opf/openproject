# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

  describe "visible_user_information?" do
    subject { component.visible_user_information? }

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
      let(:custom_field) { create(:user_custom_field, :string, visible: false) }
      let(:user) { build(:user, custom_values: [build(:custom_value, custom_field:, value: "Hello")]) }

      it { is_expected.to be(false) }
    end
  end

  describe "Custom fields" do
    let(:custom_field) { create(:user_custom_field, :string, visible:) }
    let(:user) { build_stubbed(:user, custom_values: [build(:custom_value, custom_field:, value: "Hello custom field")]) }
    
    current_user { build(:admin) }

    before do
      render_inline(component)
    end

    context "when visible" do
      let(:visible) { true }

      it "renders the field" do
        expect(page).to have_text("Hello custom field")
      end
    end

    context "when not visible" do
      let(:visible) { false }

      it "does not render the field" do
        expect(page).to have_no_text("Hello custom field")
      end
    end
  end
end
