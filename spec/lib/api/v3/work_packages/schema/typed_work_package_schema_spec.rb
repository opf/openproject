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

RSpec.describe API::V3::WorkPackages::Schema::TypedWorkPackageSchema do
  let(:project) { build(:project) }
  let(:type) { build(:type) }

  let(:current_user) { build_stubbed(:user) }

  subject { described_class.new(project:, type:) }

  before do
    login_as(current_user)
    mock_permissions_for(current_user, &:allow_everything)
  end

  it "has the project set" do
    expect(subject.project).to eql(project)
  end

  it "has the type set" do
    expect(subject.type).to eql(type)
  end

  it "does not know assignable statuses" do
    expect(subject.assignable_values(:status, current_user)).to be_nil
  end

  it "does not know assignable versions" do
    expect(subject.assignable_values(:version, current_user)).to be_nil
  end

  describe "#writable?" do
    it "percentage done is writable in work-based progress calculation mode",
       with_settings: { work_package_done_ratio: "field" } do
      expect(subject).to be_writable(:done_ratio)
    end

    it "percentage done is not writable in status-based progress calculation mode",
       with_settings: { work_package_done_ratio: "status" } do
      expect(subject).not_to be_writable(:done_ratio)
    end

    it "work is writable" do
      expect(subject).to be_writable(:estimated_hours)
    end

    it "remaining work is writable" do
      expect(subject).to be_writable(:remaining_hours)
    end

    it "start date is writable" do
      expect(subject).to be_writable(:start_date)
    end

    it "finish date is writable" do
      expect(subject).to be_writable(:due_date)
    end

    it "subject is writable" do
      expect(subject).to be_writable(:subject)
    end

    context "when the type has automatic subject generation enabled" do
      let(:type) { create(:type, patterns: { subject: { blueprint: "Hello world", enabled: true } }) }

      it "subject is not writable" do
        expect(subject).not_to be_writable(:subject)
      end
    end
  end

  describe "#milestone?" do
    before do
      allow(type)
        .to receive(:is_milestone?)
              .and_return(true)
    end

    it "is the value the type has" do
      expect(subject).to be_milestone

      allow(type)
        .to receive(:is_milestone?)
        .and_return(false)

      expect(subject).not_to be_milestone
    end

    it "has a writable date" do
      expect(subject).to be_writable(:date)
    end
  end

  describe "#assignable_custom_field_values" do
    let(:list_cf) { build_stubbed(:list_wp_custom_field) }
    let(:version_cf) { build_stubbed(:version_wp_custom_field) }

    it "is nil for a list cf" do
      expect(subject.assignable_custom_field_values(list_cf)).to be_nil
    end

    it "is nil for a version cf" do
      expect(subject.assignable_custom_field_values(version_cf)).to be_nil
    end
  end

  describe "#available_custom_fields with a linked form configuration", with_flag: { type_variants: true } do
    let(:source_type) { create(:type) }
    let(:linked_type) { create(:type) }
    let(:project) { create(:project, types: [linked_type]) }
    let!(:source_cf) do
      create(:integer_wp_custom_field).tap do |cf|
        project.work_package_custom_fields << cf
        source_type.default_variant.custom_fields << cf
      end
    end

    subject { described_class.new(project:, type: linked_type) }

    before do
      link_configuration(linked_type, source: source_type, aspect: TypeVariant::FORM_CONFIGURATION)
    end

    it "intersects the project's fields with the effective source type's fields" do
      expect(subject.available_custom_fields).to include(source_cf)
    end
  end

  describe "#available_custom_fields when the project resolves a variant",
           with_flag: { type_variants: true } do
    let(:root_type) { create(:type) }
    let(:variant) do
      create(:type_variant, type: root_type).tap do |named|
        link_configuration(named, source: root_type, aspect: TypeVariant::FORM_CONFIGURATION)
      end
    end
    let(:project) { create(:project, types: [variant]) }

    let!(:root_cf) { create(:integer_wp_custom_field, projects: [project], types: [root_type]) }
    let!(:variant_cf) { create(:integer_wp_custom_field, projects: [project], types: [variant]) }

    subject { described_class.new(project:, type: root_type) }

    context "when the variant inherits its form configuration" do
      it "answers with the root's fields" do
        expect(subject.available_custom_fields).to include(root_cf)
        expect(subject.available_custom_fields).not_to include(variant_cf)
      end
    end

    context "when the variant owns its form configuration" do
      before do
        unlink_configuration(variant, aspect: TypeVariant::FORM_CONFIGURATION)
      end

      it "answers with the variant's own fields" do
        expect(subject.available_custom_fields).to include(variant_cf)
        expect(subject.available_custom_fields).not_to include(root_cf)
      end
    end
  end
end
