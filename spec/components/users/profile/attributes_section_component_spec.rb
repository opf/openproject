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

RSpec.describe Users::Profile::AttributesSectionComponent, type: :component do
  shared_let(:section) { create(:user_custom_field_section, name: "Profile info") }
  let(:component) { described_class.new(section:, user:) }

  current_user { build(:admin) }

  context "with built-in and custom field attributes" do
    shared_let(:custom_field) do
      create(:user_custom_field, :string, name: "Job title", user_custom_field_section: section)
    end
    let(:user) do
      create(:user, firstname: "Sarah",
                    custom_values: [build(:custom_value, custom_field:, value: "Developer")])
    end

    before do
      section.update_column(:attribute_order, ["firstname", custom_field.column_name])
      render_inline(component)
    end

    it "renders the section name as the title" do
      expect(page).to have_text("Profile info")
    end

    it "renders the built-in label and value" do
      expect(page).to have_text(User.human_attribute_name("firstname"))
      expect(page).to have_text("Sarah")
    end

    it "renders the custom field label and value" do
      expect(page).to have_text("Job title")
      expect(page).to have_text("Developer")
    end
  end

  context "with a multi-value custom field" do
    shared_let(:custom_field) do
      create(:user_custom_field, :multi_list, name: "Skills", user_custom_field_section: section)
    end
    let(:user) do
      create(:user, custom_values: custom_field.possible_values.first(3).map do |v|
        build(:custom_value, custom_field:, value: v)
      end)
    end

    before do
      section.update_column(:attribute_order, [custom_field.column_name])
      render_inline(component)
    end

    it "renders each value as an accent label" do
      expect(page).to have_css("span.Label", text: "A")
      expect(page).to have_css("span.Label", text: "B")
      expect(page).to have_css("span.Label", text: "C")
    end
  end

  context "when the section has no visible attributes" do
    let(:user) { create(:user) }

    before { section.update_column(:attribute_order, []) }

    it "does not render" do
      expect(component.render?).to be(false)
    end
  end

  context "with an untitled section" do
    shared_let(:custom_field) do
      create(:user_custom_field, :string, user_custom_field_section: section)
    end
    let(:user) { create(:user, custom_values: [build(:custom_value, custom_field:, value: "x")]) }

    before do
      section.update_column(:name, nil)
      section.update_column(:attribute_order, [custom_field.column_name])
      render_inline(component)
    end

    it "renders the I18n fallback label" do
      expect(page).to have_text(I18n.t("settings.user_custom_fields.label_untitled_section"))
    end
  end
end
