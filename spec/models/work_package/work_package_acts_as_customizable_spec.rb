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

RSpec.describe WorkPackage, "acts_as_customizable" do
  shared_let(:type) { create(:type_standard) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:user) { create(:user) }
  shared_let(:status) { create(:status) }
  shared_let(:priority) { create(:priority) }

  let(:work_package) { create(:work_package, project:, type:) }
  let(:new_work_package) do
    described_class.new type:,
                        project:,
                        author: user,
                        status:,
                        priority:,
                        subject: "some subject"
  end

  def setup_custom_field(cf)
    project.work_package_custom_fields << cf
    type.custom_fields << cf
    # Void the custom field caching
    RequestStore.clear!
    cf
  end

  describe "#custom_field_values=" do
    context "with an unpersisted work package and a version custom field" do
      subject(:wp_with_assignee_cf) do
        setup_custom_field(version_cf)
        new_work_package.custom_field_values = { version_cf.id.to_s => version }
        new_work_package
      end

      let(:version) { create(:version, project:) }
      let(:version_cf) { create(:version_wp_custom_field, is_required: true) }

      it "results in a valid work package" do
        expect(wp_with_assignee_cf)
          .to be_valid
      end

      it "sets the value" do
        expect(wp_with_assignee_cf.send(version_cf.attribute_getter))
          .to eql version
      end
    end
  end

  describe "#custom_field_values" do
    subject(:work_package) do
      setup_custom_field(custom_field)
      new_work_package
    end

    context "with a multi-value list custom field without default value" do
      let(:custom_field) { create(:wp_custom_field, :multi_list) }

      it "returns an array with a CustomValue with nil value" do
        expect(work_package.custom_field_values)
          .to match([
                      an_instance_of(CustomValue).and(having_attributes(value: nil, custom_field_id: custom_field.id))
                    ])
      end
    end

    context "with a multi-value list custom field with default value of 1 option" do
      let(:custom_field) { create(:wp_custom_field, :multi_list, default_options: ["B"]) }

      it "returns an array with a CustomValue whose value is the stringified id of the default custom option" do
        option_b = custom_field.custom_options.find_by(value: "B")
        expect(work_package.custom_field_values)
          .to match([
                      an_instance_of(CustomValue).and(having_attributes(value: option_b.id.to_s,
                                                                        custom_field_id: custom_field.id))
                    ])
      end
    end

    context "with a multi-value list custom field with default value of multiple options" do
      let(:custom_field) { create(:wp_custom_field, :multi_list, default_options: ["D", "B", "F"]) }

      it "returns an array with CustomValues whose values are the stringified ids of the default custom options" do
        option_d = custom_field.custom_options.find_by(value: "D")
        option_b = custom_field.custom_options.find_by(value: "B")
        option_f = custom_field.custom_options.find_by(value: "F")
        expect(work_package.custom_field_values)
          .to match([
                      an_instance_of(CustomValue).and(having_attributes(value: option_b.id.to_s,
                                                                        custom_field_id: custom_field.id)),
                      an_instance_of(CustomValue).and(having_attributes(value: option_d.id.to_s,
                                                                        custom_field_id: custom_field.id)),
                      an_instance_of(CustomValue).and(having_attributes(value: option_f.id.to_s,
                                                                        custom_field_id: custom_field.id))
                    ])
      end
    end
  end

  describe "#custom_field_:id" do
    let(:included_cf) { build(:work_package_custom_field) }
    let(:other_cf) { build(:work_package_custom_field) }

    before do
      included_cf.save
      other_cf.save

      setup_custom_field(included_cf)
    end

    it "says to respond to valid custom field accessors" do
      expect(work_package).to respond_to(included_cf.attribute_getter)
    end

    it "really responds to valid custom field accessors" do
      expect(work_package.send(included_cf.attribute_getter)).to be_nil
    end

    it "says to not respond to foreign custom field accessors" do
      expect(work_package).not_to respond_to(other_cf.attribute_getter)
    end

    it "does really not respond to foreign custom field accessors" do
      expect { work_package.send(other_cf.attribute_getter) }.to raise_error(NoMethodError)
    end
  end

  describe "#valid?" do
    let(:cf1) { create(:work_package_custom_field, is_required: true) }
    let(:cf2) { create(:work_package_custom_field, is_required: true) }

    it "does not duplicate error messages when invalid" do
      # create work_package with one required custom field
      work_package = new_work_package
      # work_package.reload
      setup_custom_field(cf1)

      # set that custom field with a value, should be fine
      work_package.custom_field_values = { cf1.id => "test" }
      work_package.save!(context: :saving_custom_fields)
      work_package.reload

      # now give the work_package another required custom field, but don't assign a value
      setup_custom_field(cf2)
      # custom_field_values needs to be touched
      work_package.custom_values_to_validate = work_package.custom_field_values

      # that should not be valid
      expect(work_package).not_to be_valid(:saving_custom_fields)

      # assert that there is only one error
      expect(work_package.errors.size).to eq 1
      expect(work_package.errors[cf2.attribute_name].size).to eq 1
    end
  end

  it_behaves_like "acts_as_customizable included", admin_only_allowed: false, comments: false do
    let(:model_instance) { work_package }
    let(:new_model_instance) { new_work_package }
    let(:custom_field) { create(:string_wp_custom_field) }
    before do
      setup_custom_field(custom_field)
    end
  end

  describe ".preload_available_custom_fields/#available_custom_fields" do
    let(:project) { create(:project) }
    let(:type) { create(:type) }
    let(:work_package) do
      build(:work_package,
            project:,
            type:)
    end

    let(:project2) { create(:project) }
    let(:type2) { create(:type) }
    let(:work_package2) do
      build(:work_package,
            project: project2,
            type: type2)
    end

    let!(:custom_field_of_project_and_type) do
      create(:work_package_custom_field,
             name: "Custom field of type and project").tap do |cf|
        project.work_package_custom_fields << cf
        type.custom_fields << cf
      end
    end
    let!(:custom_field_of_project_not_type) do
      create(:work_package_custom_field,
             name: "Custom field of project not type").tap do |cf|
        project.work_package_custom_fields << cf
      end
    end
    let!(:custom_field_of_type_not_project) do
      create(:work_package_custom_field,
             name: "Custom field of type not project").tap do |cf|
        type.custom_fields << cf
      end
    end
    let!(:custom_field_for_all_and_type) do
      create(:work_package_custom_field,
             name: "Custom field for all and type",
             is_for_all: true).tap do |cf|
        type.custom_fields << cf
      end
    end
    let!(:custom_field_for_all_not_type) do
      create(:work_package_custom_field,
             name: "Custom field for all not type",
             is_for_all: true)
    end

    let!(:custom_field_of_projects_and_types_for_all) do
      create(:work_package_custom_field,
             name: "Custom field for all and many types and projects",
             is_for_all: true).tap do |cf|
        project.work_package_custom_fields << cf
        type.custom_fields << cf
        project2.work_package_custom_fields << cf
        type2.custom_fields << cf
      end
    end

    context "when preloading the custom fields" do
      before do
        described_class.preload_available_custom_fields([work_package, work_package2])
        # Bad replacement to check that no database query is run.
        allow(WorkPackageCustomField)
          .to receive(:left_joins)
                .and_call_original
      end

      it "returns all custom fields of the project and type for work_package" do
        expect(work_package.available_custom_fields)
          .to contain_exactly(custom_field_of_project_and_type,
                              custom_field_for_all_and_type,
                              custom_field_of_projects_and_types_for_all)
      end

      it "returns all custom fields of the project and type for work_package2" do
        expect(work_package2.available_custom_fields)
          .to contain_exactly(custom_field_of_projects_and_types_for_all)
      end

      it "does not call the database" do
        work_package.available_custom_fields
        work_package2.available_custom_fields

        expect(WorkPackageCustomField)
          .not_to have_received(:left_joins)
      end
    end

    context "when not preloading the custom fields" do
      it "returns all custom fields of the project and type" do
        expect(work_package.available_custom_fields)
          .to contain_exactly(custom_field_of_project_and_type,
                              custom_field_for_all_and_type,
                              custom_field_of_projects_and_types_for_all)
      end
    end
  end
end
