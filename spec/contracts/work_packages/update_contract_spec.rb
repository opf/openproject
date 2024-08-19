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

require "spec_helper"
require "contracts/work_packages/shared_base_contract"

RSpec.describe WorkPackages::UpdateContract do
  shared_let(:persistent_project) { create(:project, public: false) }
  shared_let(:type) { create(:type) }
  let(:work_package_project) { persistent_project }
  let(:work_package) do
    build_stubbed(:work_package,
                  project: work_package_project,
                  type:,
                  status:) do |wp|
      wp_scope = double("wp scope")

      allow(WorkPackage)
        .to receive(:visible)
        .with(user)
        .and_return(wp_scope)

      allow(wp_scope)
        .to receive(:exists?) do |id|
        permissions.include?(:view_work_packages) && id == wp.id
      end
    end
  end
  let(:user) { build_stubbed(:user) }
  let(:status) { build_stubbed(:status) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(*permissions, project: work_package_project) if work_package_project
    end
  end

  subject(:contract) { described_class.new(work_package, user) }

  it_behaves_like "work package contract" do
    let(:work_package) do
      build_stubbed(:work_package,
                    project: work_package_project)
    end
  end

  describe "lock_version" do
    context "no lock_version present" do
      before do
        work_package.lock_version = nil
        contract.validate
      end

      it { expect(contract.errors.symbols_for(:base)).to include(:error_conflict) }
    end

    context "lock_version changed" do
      before do
        work_package.lock_version += 1
        contract.validate
      end

      it { expect(contract.errors.symbols_for(:base)).to include(:error_conflict) }
    end

    context "lock_version present and unchanged" do
      before do
        contract.validate
      end

      it { expect(contract.errors.symbols_for(:base)).not_to include(:error_conflict) }
    end
  end

  describe "authorization" do
    let(:attributes) { {} }

    before do
      work_package.attributes = attributes
      contract.validate
    end

    context "full access" do
      it "is valid" do
        expect(contract.errors).to be_empty
      end
    end

    context "no read access" do
      let(:permissions) { [:edit_work_packages] }

      it { expect(contract.errors.symbols_for(:base)).to include(:error_not_found) }
    end

    context "no write access" do
      let(:permissions) { [:view_work_packages] }

      it { expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized) }
    end

    context "only comment permission" do
      let(:permissions) { %i[view_work_packages add_work_package_notes] }

      context "when only adding a journal" do
        let(:attributes) { { journal_notes: "some notes" } }

        it "is valid" do
          expect(contract.errors).to be_empty
        end
      end

      context "when changing more than a journal" do
        let(:attributes) { { journal_notes: "some notes", subject: "blubs" } }

        it "is invalid" do
          expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized)
        end
      end
    end

    context "only assign_versions permission" do
      let(:permissions) { %i[view_work_packages assign_versions] }

      it "is valid" do
        expect(contract.errors).to be_empty
      end
    end
  end

  describe "project_id" do
    let(:target_project) { create(:project, types: [type]) }
    let(:target_permissions) { [:move_work_packages] }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project *permissions, project: work_package_project
        mock.allow_in_project *target_permissions, project: target_project
      end

      allow(work_package).to receive(:project) do
        if work_package.project_id == target_project.id
          target_project
        else
          work_package_project
        end
      end

      work_package.project = target_project

      contract.validate
    end

    context "if the user has the permissions" do
      it("is valid") { expect(contract.errors).to be_empty }
    end

    context "if the user lacks the permissions" do
      let(:target_permissions) { [] }

      it "is invalid" do
        expect(contract.errors.symbols_for(:project_id)).to contain_exactly(:error_readonly)
      end
    end
  end

  describe "version" do
    let(:version) { build_stubbed(:version) }

    before do
      allow(work_package)
        .to receive(:assignable_versions)
        .and_return([version])

      work_package.attributes = attributes

      contract.validate
    end

    context "having full access" do
      context "with an assignable_version" do
        let(:attributes) { { version_id: version.id } }

        it "is valid" do
          expect(contract.errors).to be_empty
        end
      end

      context "with an unassignable_version" do
        let(:attributes) { { version_id: version.id + 1 } }

        it "adds an error" do
          expect(contract.errors.symbols_for(:version_id))
            .to include(:inclusion)
        end
      end
    end

    context "write access" do
      let(:permissions) { %i[view_work_packages edit_work_packages] }

      context "if assigning a version" do
        let(:attributes) { { version_id: version.id } }

        it "adds an error" do
          expect(contract.errors.symbols_for(:version_id))
            .to include(:error_readonly)
        end
      end
    end
  end

  describe "ignore_non_working_days" do
    context "when having children and not being scheduled manually" do
      before do
        allow(work_package)
          .to receive(:leaf?)
                .and_return(false)

        work_package.ignore_non_working_days = !work_package.ignore_non_working_days
        work_package.schedule_manually = false

        contract.validate
      end

      it "is invalid" do
        expect(contract.errors.symbols_for(:ignore_non_working_days))
          .to contain_exactly(:error_readonly)
      end
    end

    context "when having children and being scheduled manually" do
      before do
        allow(work_package)
          .to receive(:leaf?)
                .and_return(false)

        work_package.ignore_non_working_days = !work_package.ignore_non_working_days
        work_package.schedule_manually = true

        contract.validate
      end

      it "is valid" do
        expect(contract.errors).to be_empty
      end
    end
  end

  describe "with children" do
    context "changing to milestone" do
      let(:milestone) { build_stubbed(:type, is_milestone: true) }
      let(:children) { [build_stubbed(:work_package)] }

      before do
        work_package.type = milestone
        allow(work_package).to receive(:children).and_return children
        contract.validate
      end

      it "adds an error because cannot change to milestone with children" do
        expect(contract.errors.symbols_for(:type)).to include(:cannot_be_milestone_due_to_children)
      end
    end
  end

  describe "parent_id" do
    shared_let(:parent) { create(:work_package) }

    let(:parent_visible) { true }

    before do
      work_package.parent_id = parent.id
      allow(work_package.parent).to receive(:visible?).and_return(parent_visible)
      contract.validate
    end

    context "if the user has only edit permissions" do
      it { expect(contract.errors.symbols_for(:parent_id)).to include(:error_readonly) }
    end

    context "if the user has edit and subtasks permissions" do
      let(:permissions) { %i[edit_work_packages view_work_packages manage_subtasks] }

      it("is valid") do
        expect(contract.errors).to be_empty
      end

      describe "invalid lock version" do
        before do
          work_package.lock_version = 9999
          contract.validate
        end

        it { expect(contract.errors.symbols_for(:base)).to include(:error_conflict) }
      end
    end

    context "no write access" do
      let(:permissions) { [:view_work_packages] }

      it { expect(contract.errors.symbols_for(:parent_id)).to include(:error_readonly) }
    end

    context "with manage_subtasks permission" do
      let(:permissions) { %i[view_work_packages manage_subtasks] }

      it("is valid") do
        expect(contract.errors).to be_empty
      end

      describe "changing more than the parent_id" do
        before do
          work_package.subject = "Foobar!"
          contract.validate
        end

        it { expect(contract.errors.symbols_for(:subject)).to include(:error_readonly) }
      end
    end

    context "when the user does not have access to the parent" do
      let(:parent_visible) { false }

      it { expect(contract.errors.symbols_for(:parent_id)).to include(:error_unauthorized) }
    end
  end

  describe "#writable_attributes" do
    subject { contract.writable_attributes }

    context "for a user having only the edit_work_packages permission" do
      let(:permissions) { %i[edit_work_packages] }

      it "includes all attributes except version_id" do
        expect(subject)
          .to include("subject", "start_date", "description")

        expect(subject)
          .not_to include("version_id", "version")
      end
    end

    context "for a user having only the assign_versions permission" do
      let(:permissions) { %i[assign_versions] }

      it "includes all attributes except version_id" do
        expect(subject)
          .to include("version_id", "version")

        expect(subject)
          .not_to include("subject", "start_date", "description")
      end
    end
  end

  describe "readonly status" do
    context "with the status being readonly", with_ee: %i[readonly_work_packages] do
      let(:status) { build_stubbed(:status, is_readonly: true) }

      describe "updating the priority" do
        let(:new_priority) { build_stubbed(:priority) }

        before do
          work_package.priority = new_priority

          contract.validate
        end

        it "is invalid" do
          expect(contract)
            .not_to be_valid
        end

        it "adds an error to the written to attribute" do
          expect(contract.errors.symbols_for(:priority_id))
            .to include(:error_readonly)
        end

        it "adds an error to base to better explain" do
          expect(contract.errors.symbols_for(:base))
            .to include(:readonly_status)
        end
      end

      describe "updating the custom field values" do
        let(:cf1) { create(:string_wp_custom_field) }

        before do
          work_package_project.work_package_custom_fields << cf1
          type.custom_fields << cf1
          work_package.custom_field_values = { cf1.id => "test" }
          contract.validate
        end

        shared_examples_for "custom_field readonly errors" do
          it "adds an error to the written custom field attribute" do
            expect(contract.errors.symbols_for(cf1.attribute_name.to_sym))
              .to include(:error_readonly)
          end

          it "adds an error to base to better explain" do
            expect(contract.errors.symbols_for(:base))
              .to include(:readonly_status)
          end
        end

        context "when the subject does not extends OpenProject::ChangedBySystem" do
          include_examples "custom_field readonly errors"
        end

        context "when the subject extends OpenProject::ChangedBySystem" do
          before do
            work_package.extend(OpenProject::ChangedBySystem)
          end

          include_examples "custom_field readonly errors"
        end
      end
    end
  end

  describe "remaining hours" do
    context "when is not a parent" do
      before do
        contract.validate
      end

      context "when has not changed" do
        it("is valid") { expect(contract.errors.empty?).to be true }
      end

      context "when has changed" do
        before do
          work_package.remaining_hours = 10
        end

        it("is valid") { expect(contract.errors.empty?).to be true }
      end
    end

    context "when is a parent" do
      let(:work_package) do
        build_stubbed(:work_package,
                      project: work_package_project,
                      children: [build_stubbed(:work_package, project: work_package_project)],
                      type:,
                      status:) do |wp|
          wp_scope = instance_double(ActiveRecord::Relation)

          allow(WorkPackage)
            .to receive(:visible)
            .with(user)
            .and_return(wp_scope)

          allow(wp_scope)
            .to receive(:exists?) do |id|
            permissions.include?(:view_work_packages) && id == wp.id
          end
        end
      end

      before do
        contract.validate
      end

      context "when has not changed" do
        it("is valid") { expect(contract.errors.empty?).to be true }
      end

      context "when has changed" do
        before do
          work_package.remaining_hours = 10
        end

        it("is valid") { expect(contract.errors.empty?).to be true }
      end
    end
  end
end
