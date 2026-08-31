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

RSpec.describe AttributeHelpText::Project do
  def create_cf_help_text(custom_field)
    # Need to clear the request store after every creation as the available attributes are cached
    RequestStore.clear!
    # need to clear the cache to free the memoized
    Rails.cache.clear
    create(:project_help_text, attribute_name: custom_field.attribute_name)
  end

  let(:project_custom_field) { create(:text_project_custom_field) }

  let(:cf_instance) do
    create_cf_help_text(project_custom_field)
  end

  it_behaves_like "acts_as_attachable included" do
    let(:model_instance) { create(:project_help_text) }
    let(:project) { create(:project) }
  end

  describe ".available_attributes" do
    subject { described_class.available_attributes }

    it "returns a hash of potential attributes" do
      expect(subject).to be_a Hash
    end
  end

  describe ".used_attributes" do
    let!(:instance) { create(:project_help_text) }

    subject { described_class.used_attributes instance.type }

    it "returns used attributes" do
      expect(subject).to eq([instance.attribute_name])
    end
  end

  describe ".visible" do
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let!(:static_instance) { create(:project_help_text, attribute_name: "name") }
    let!(:cf_instance_active) do
      custom_field = create(:text_project_custom_field)
      project.project_custom_fields << custom_field
      create_cf_help_text(custom_field)
    end
    let!(:cf_instance_for_all) do
      custom_field = create(:text_project_custom_field, is_for_all: true)
      create_cf_help_text(custom_field)
    end

    before do
      cf_instance
    end

    subject { described_class.visible(user) }

    it "returns the help text for all attributes" do
      expect(subject)
        .to contain_exactly(cf_instance, static_instance, cf_instance_active, cf_instance_for_all)
    end
  end

  describe ".cached" do
    let(:user) { create(:user) }
    let!(:project_help_text) { create(:project_help_text, attribute_name: "status") }
    let!(:wp_help_text) { create(:work_package_help_text, attribute_name: "status") }

    subject { described_class.cached(user) }

    it "returns only Project help texts, not WorkPackage help texts with the same attribute name" do
      expect(subject["status"]).to eq(project_help_text)
      expect(subject["status"]).not_to eq(wp_help_text)
      expect(subject["status"]).to be_a(described_class)
    end

    it "does not include help texts of other types" do
      expect(subject.values).to all(be_a(described_class))
    end
  end

  describe "validations" do
    subject { build(:project_help_text) }

    it "validates presence of help text" do
      expect(subject).to validate_presence_of(:help_text)
    end

    it "validates uniqueness of attribute name" do
      expect(subject).to validate_uniqueness_of(:attribute_name).scoped_to(:type)
    end

    it "validates inclusion of attribute name" do
      expect(subject).to validate_inclusion_of(:attribute_name)
        .in_array(%w(name identifier description public active status status_explanation parent))
    end
  end

  describe "normalization" do
    it "normalizes attribute_name" do
      expect(subject).to normalize(:attribute_name).from("parent_id").to("parent")
    end
  end

  describe "instance" do
    subject { build(:project_help_text) }

    it "provides a caption of its type" do
      expect(subject.attribute_scope).to eq "Project"
      expect(subject.type_caption).to eq "Project"
    end
  end

  describe "destroy" do
    context "when the custom field is destroyed" do
      before do
        cf_instance
        project_custom_field.destroy
      end

      it "also destroys the instance" do
        expect { cf_instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
