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

RSpec.describe WorkPackages::CreateService, "integration", type: :model do
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages manage_subtasks assign_versions])
  end

  let(:type) do
    create(:type,
           custom_fields: [custom_field])
  end
  let(:default_type) do
    create(:type_standard)
  end
  let(:project) { create(:project, types: [type, default_type]) }
  let(:parent) do
    create(:work_package,
           subject: "parent",
           schedule_manually: false,
           project:,
           type:)
  end
  let(:instance) { described_class.new(user:) }
  let(:custom_field) { create(:work_package_custom_field) }
  let(:other_status) { create(:status) }
  let(:default_status) { create(:default_status) }
  let(:priority) { create(:priority) }
  let(:default_priority) { create(:default_priority) }
  let(:attributes) { {} }
  let(:new_work_package) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(**attributes)
  end

  before do
    other_status
    default_status
    priority
    default_priority
    type
    default_type
    login_as(user)
  end

  context "when the only type of the project is a milestone" do
    let(:default_type) do
      create(:type_milestone)
    end
    let(:project) { create(:project, types: [default_type]) }

    describe "call without date attributes" do
      let(:attributes) do
        { subject: "blubs", project: }
      end

      it "creates the default type without errors" do
        expect(service_result).to be_success
        expect(service_result.errors).to be_empty
      end
    end

    describe "call with a parent non-milestone with dates" do
      let(:parent) do
        create(:work_package,
               project:,
               schedule_manually: false,
               start_date: "2024-01-01",
               due_date: "2024-01-10",
               type: create(:type))
      end
      let(:attributes) do
        { subject: "blubs", project:, parent: }
      end

      it "creates the default type without errors" do
        expect(service_result).to be_success
        expect(service_result.errors).to be_empty
      end
    end
  end

  describe "#call" do
    let(:attributes) do
      { subject: "blubs",
        project:,
        estimated_hours: 10.0,
        remaining_hours: 5.0,
        parent:,
        start_date: Date.current,
        due_date: Date.current + 3.days }
    end

    it "creates the work_package with the provided attributes and sets the user as a watcher" do
      # successful
      expect(service_result)
        .to be_success

      # attributes set as desired
      attributes.each do |key, value|
        expect(new_work_package.send(key))
          .to eql value
      end

      # service user as author
      expect(new_work_package.author)
        .to eql(user)

      # assign the default status
      expect(new_work_package.status)
        .to eql(default_status)

      # assign the first type in the project (not related to is_default)
      expect(new_work_package.type)
        .to eql(type)

      # assign the default priority
      expect(new_work_package.priority)
        .to eql(default_priority)

      # parent updated
      parent.reload
      expect(parent.derived_done_ratio)
        .to eq 50
      expect(parent.start_date)
        .to eql attributes[:start_date]
      expect(parent.due_date)
        .to eql attributes[:due_date]

      # adds the user (author) as watcher
      expect(new_work_package.watcher_users)
        .to contain_exactly(user)
    end

    it "creates only one WorkflowJob and one JournalsCompletedJob for the created work package" do
      # avoid setting the parent to avoid creating unrelated jobs
      attributes[:parent] = nil

      # create objects before clearing jobs to make sure unrelated jobs are cleared
      project
      clear_enqueued_jobs
      expect(service_result).to be_success

      got_enqueued_jobs = enqueued_jobs.pluck(:job)
      expect(got_enqueued_jobs)
        .to contain_exactly(WorkPackages::WorkflowJob,
                            Notifications::WorkflowJob,
                            Journals::CompletedJob)
    end

    describe "setting the attachments" do
      let!(:other_users_attachment) do
        create(:attachment, container: nil, author: create(:user))
      end
      let!(:users_attachment) do
        create(:attachment, container: nil, author: user)
      end

      it "reports on invalid attachments and sets the new if everything is valid" do
        result = instance.call(**attributes, attachment_ids: [other_users_attachment.id])

        expect(result)
          .to be_failure

        expect(result.errors.symbols_for(:attachments))
          .to contain_exactly(:does_not_exist)

        # The parent work package
        expect(WorkPackage.count)
          .to be 1

        expect(other_users_attachment.reload.container)
          .to be_nil

        result = instance.call(**attributes, attachment_ids: [users_attachment.id])

        expect(result)
          .to be_success

        expect(result.result.attachments)
          .to contain_exactly(users_attachment)

        expect(users_attachment.reload.container)
          .to eql result.result
      end
    end

    describe "with a child creation with both dates and work" do
      let(:start_date) { Date.current }
      let(:due_date) { start_date + 3.days }
      let(:attributes) do
        {
          subject: "child",
          project:,
          parent:,
          estimated_hours: 5,
          start_date:,
          due_date:
        }
      end

      it "correctly updates the parent values" do
        expect(service_result)
          .to be_success

        parent.reload
        expect(parent.derived_estimated_hours).to eq(5)
        expect(parent.start_date).to eq(start_date)
        expect(parent.due_date).to eq(due_date)
      end
    end

    describe "writing timestamps" do
      shared_let(:user) { create(:admin) }
      shared_let(:other_user) { create(:user) }

      let(:created_at) { 11.days.ago }

      let(:attributes) do
        {
          subject: "child",
          project:,
          author: other_user,
          created_at:
        }
      end

      context "when enabled", with_settings: { apiv3_write_readonly_attributes: true } do
        it "sets created_at accordingly" do
          expect(service_result)
            .to be_success

          expect(new_work_package.created_at).to equal_time_without_usec(created_at)
        end
      end

      context "when enabled, but disallowed field", with_settings: { apiv3_write_readonly_attributes: true } do
        let(:attributes) do
          {
            subject: "child",
            project:,
            author: other_user,
            updated_at: created_at
          }
        end

        it "rejects updated_at" do
          expect(service_result)
            .not_to be_success

          expect(new_work_package.errors.symbols_for(:updated_at))
            .to contain_exactly(:error_readonly)
        end
      end

      context "when disabled", with_settings: { apiv3_write_readonly_attributes: false } do
        it "rejects the creation" do
          expect(service_result)
            .not_to be_success

          expect(new_work_package.errors.symbols_for(:created_at))
            .to contain_exactly(:error_readonly)
        end
      end
    end

    describe "setting the associated versions" do
      let!(:version1) { create(:version, project:) }
      let!(:version2) { create(:version, project:) }

      context "with target_version_ids" do
        let(:attributes) do
          { subject: "test wp", project:, target_version_ids: [version1.id, version2.id] }
        end

        it "creates the work package with the specified target versions" do
          expect(service_result).to be_success

          expect(new_work_package.target_versions.reload).to contain_exactly(version1, version2)
        end
      end

      context "with observed_in_version_ids" do
        let(:attributes) do
          { subject: "test wp", project:, observed_in_version_ids: [version1.id] }
        end

        it "creates the work package with the specified observed_in versions" do
          expect(service_result).to be_success

          expect(new_work_package.observed_in_versions.reload).to contain_exactly(version1)
        end
      end

      context "with only version_id" do
        let(:attributes) do
          { subject: "test wp", project:, version_id: version1.id }
        end

        it "syncs version_id to target_versions" do
          expect(service_result).to be_success

          expect(new_work_package.target_versions.reload).to contain_exactly(version1)
        end
      end

      context "with both version_id and target_version_ids" do
        let(:attributes) do
          { subject: "test wp", project:, version_id: version1.id, target_version_ids: [version2.id] }
        end

        it "allows the creation" do
          expect(service_result).to be_success

          expect(new_work_package.target_versions.reload).to contain_exactly(version2)
          expect(new_work_package.version.reload).to eq(version1)
        end
      end

      context "with non-assignable version IDs" do
        let(:other_version) { create(:version) }
        let(:attributes) do
          { subject: "test wp", project:, target_version_ids: [other_version.id] }
        end

        it "rejects the creation" do
          expect(service_result).to be_failure

          expect(service_result.errors.symbols_for(:target_versions)).to include(:inclusion)
        end
      end
    end
  end
end
