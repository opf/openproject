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

RSpec.describe UserCustomField do
  describe "validations" do
    it "is invalid without a section" do
      cf = build(:user_custom_field, custom_field_section_id: nil)
      expect(cf).not_to be_valid
      expect(cf.errors[:custom_field_section_id]).to be_present
    end

    it "is valid with a section" do
      expect(create(:user_custom_field)).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a UserCustomFieldSection" do
      section = create(:user_custom_field_section)
      cf = create(:user_custom_field, user_custom_field_section: section)
      expect(cf.user_custom_field_section).to eq(section)
    end
  end

  describe "#type_name" do
    it "returns :label_user_plural" do
      expect(described_class.new.type_name).to eq(:label_user_plural)
    end
  end

  describe "defaults" do
    it "defaults visible_on_user_card to false" do
      cf = create(:user_custom_field)
      expect(cf.visible_on_user_card).to be(false)
    end
  end

  describe "attribute_order integration" do
    let(:section) { create(:user_custom_field_section) }

    it "appends itself to the section's attribute_order on creation" do
      cf = create(:user_custom_field, user_custom_field_section: section)
      expect(section.reload.attribute_order).to include(cf.column_name)
    end

    it "orders fields by creation order when multiple are created" do
      cf1 = create(:user_custom_field, user_custom_field_section: section)
      cf2 = create(:user_custom_field, user_custom_field_section: section)
      expect(section.reload.attribute_order).to eq([cf1.column_name, cf2.column_name])
    end

    it "removes itself from the section's attribute_order on destruction" do
      cf = create(:user_custom_field, user_custom_field_section: section)
      cf.destroy
      expect(section.reload.attribute_order).not_to include(cf.column_name)
    end

    it "scopes positions per section (each section is independent)" do
      other_section = create(:user_custom_field_section)
      cf1 = create(:user_custom_field, user_custom_field_section: section)
      cf2 = create(:user_custom_field, user_custom_field_section: other_section)
      expect(section.reload.attribute_order).to eq([cf1.column_name])
      expect(other_section.reload.attribute_order).to eq([cf2.column_name])
    end
  end

  describe ".visible" do
    let!(:admin_only_cf) { create(:user_custom_field, admin_only: true) }
    let!(:public_cf)     { create(:user_custom_field, admin_only: false) }

    context "for an admin" do
      it "returns all custom fields" do
        expect(described_class.visible(build(:admin))).to include(admin_only_cf, public_cf)
      end
    end

    context "for a non-admin" do
      it "returns only non-admin_only custom fields" do
        expect(described_class.visible(build(:user))).to include(public_cf)
        expect(described_class.visible(build(:user))).not_to include(admin_only_cf)
      end
    end
  end

  describe "semantic_key" do
    it "exposes the known semantic keys via the enum" do
      expect(described_class.semantic_keys).to eq("job_title" => "job_title")
    end

    it "allows a nil semantic_key (no purpose)" do
      cf = build(:user_custom_field, semantic_key: nil)
      cf.valid?
      expect(cf.errors[:semantic_key]).to be_empty
    end

    it "allows multiple fields without a semantic_key" do
      create(:user_custom_field, semantic_key: nil)
      second = build(:user_custom_field, semantic_key: nil)
      second.valid?
      expect(second.errors[:semantic_key]).to be_empty
    end

    it "is invalid when the semantic_key is already taken" do
      create(:user_custom_field, semantic_key: "job_title")
      duplicate = build(:user_custom_field, semantic_key: "job_title")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:semantic_key]).to be_present
    end

    it "enforces uniqueness at the database level" do
      create(:user_custom_field, semantic_key: "job_title")

      expect do
        described_class.new(
          name: "Another job title", field_format: "string",
          custom_field_section: create(:user_custom_field_section), semantic_key: "job_title"
        ).save!(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    describe ".with_semantic_key / .for_semantic_key" do
      let!(:job_title_cf) { create(:user_custom_field, semantic_key: "job_title") }
      let!(:other_cf)     { create(:user_custom_field, semantic_key: nil) }

      it "returns the matching field" do
        expect(described_class.with_semantic_key(:job_title)).to contain_exactly(job_title_cf)
        expect(described_class.for_semantic_key(:job_title)).to eq(job_title_cf)
      end
    end
  end

  describe "section deletion restriction" do
    let(:section) { create(:user_custom_field_section) }
    let!(:cf) { create(:user_custom_field, user_custom_field_section: section) }

    it "raises when attempting to destroy a section that still holds custom fields" do
      expect { section.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "removes itself from the section's attribute_order when destroyed individually" do
      cf.destroy!
      expect(section.reload.attribute_order).not_to include(cf.column_name)
    end
  end
end
