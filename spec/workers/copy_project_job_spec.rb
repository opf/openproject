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

RSpec.describe CopyProjectJob, type: :model, with_good_job_batches: [CopyProjectJob, SendCopyProjectStatusEmailJob] do
  shared_let(:admin) { create(:admin) }
  shared_let(:user_de) { create(:admin, language: :de) }
  let(:params) { { name: "Copy", identifier: "copy" } }
  let(:mail_double) { double("Mail::Message", deliver: true) } # rubocop:disable RSpec/VerifiedDoubles

  before { allow(mail_double).to receive(:deliver_later) }

  describe "with a source project having invalid work packages" do
    shared_let(:type) { create(:type_bug) }
    shared_let(:source_project) { create(:project, types: [type]) }

    shared_let(:work_package_with_model_errors) do
      # done ratio must be between 0 and 100, this is a model validation
      create(:work_package, :skip_validations,
             project: source_project, type:,
             subject: "wp with invalid done_ratio",
             done_ratio: 101)
    end
    shared_let(:work_package_with_contract_errors) do
      # remaining work must be less than or equal to work, this is a WorkPackages::BaseContract validation
      create(:work_package, :skip_validations,
             project: source_project, type:,
             subject: "wp with invalid work and remaining work",
             remaining_hours: 10, estimated_hours: 2)
    end

    let(:job_args) do
      {
        target_project_params: params,
        associations_to_copy: [:work_packages]
      }
    end

    let(:params) { { name: "Copy", identifier: "copy" } }

    it "copies the project and invalid work packages without reporting any errors", :aggregate_failures do
      copy_job = nil
      batch = GoodJob::Batch.enqueue(user: admin, source_project:) do
        copy_job = described_class.perform_later(**job_args)
      end
      GoodJob.perform_inline
      batch.reload

      copied_project = Project.find_by(identifier: params[:identifier])
      expect(copied_project).to eq(batch.properties[:target_project])

      # all work packages were copied, even if they are invalid
      expect(copied_project.work_packages.count).to eq(source_project.work_packages.count)
      # no errors reported
      expect(batch.properties[:errors]).to be_empty

      # expect to create a status
      expect(copy_job.job_status).to be_present
      expect(copy_job.job_status[:status]).to eq "success"
      expect(copy_job.job_status[:payload]["redirect"]).to include "/projects/copy"

      expected_link = { "href" => "/api/v3/projects/#{copied_project.id}", "title" => copied_project.name }
      expect(copy_job.job_status[:payload]["_links"]["project"]).to eq(expected_link)
    end

    context "when the source project has automatically generated subjects" do
      before do
        type.default_variant.update!(patterns: { subject: { blueprint: "wp {{id}} in project {{project_id}}", enabled: true } })
      end

      it "copies the project without reporting any errors and generates subjects different from source project" do
        batch = GoodJob::Batch.enqueue(user: admin, source_project:) do
          described_class.perform_later(**job_args)
        end
        GoodJob.perform_inline
        batch.reload

        copied_project = Project.find_by(identifier: params[:identifier])

        # all work packages were copied, even if they are invalid
        expect(copied_project.work_packages.count).to eq(source_project.work_packages.count)
        # no errors reported
        expect(batch.properties[:errors]).to be_empty

        # generated subjects are different from source project
        copied_project.work_packages.each do |work_package|
          expect(work_package.subject).to eq("wp #{work_package.id} in project #{copied_project.id}")
        end
      end
    end
  end

  describe "copy project succeeds with invalid custom fields" do
    let(:source_project) { create(:project, types: [type]) }

    let!(:work_package) { create(:work_package, project: source_project, type:) }

    let(:type) { create(:type_bug) }
    let(:custom_field) do
      create(:work_package_custom_field, name: "required_field", field_format: "text", is_required: true, is_for_all: true)
    end

    let(:job_args) do
      {
        target_project_params: params,
        associations_to_copy: [:work_packages]
      }
    end

    let(:params) { { name: "Copy", identifier: "copy", work_package_custom_field_ids: [custom_field.id] } }

    before do
      source_project.work_package_custom_fields << custom_field
      type.default_variant.custom_fields << custom_field
    end

    it "copies the project", :aggregate_failures do
      copy_job = nil
      batch = GoodJob::Batch.enqueue(user: admin, source_project:) do
        copy_job = described_class.perform_later(**job_args)
      end
      GoodJob.perform_inline
      batch.reload

      copied_project = Project.find_by(identifier: params[:identifier])

      expect(copied_project).to eq(batch.properties[:target_project])
      expect(batch.properties[:errors]).to be_empty

      # expect to create a status
      expect(copy_job.job_status).to be_present
      expect(copy_job.job_status[:status]).to eq "success"
      expect(copy_job.job_status[:payload]["redirect"]).to include "/projects/copy"

      expected_link = { "href" => "/api/v3/projects/#{copied_project.id}", "title" => copied_project.name }
      expect(copy_job.job_status[:payload]["_links"]["project"]).to eq(expected_link)
    end
  end

  describe "project has an invalid repository" do
    let(:source_project) do
      project = create(:project)

      # add invalid repo
      repository = Repository::Git.new(scm_type: :existing, project:)
      repository.save!(validate: false)
      project.reload
      project
    end

    before do
      allow(User).to receive(:current).and_return(admin)
    end

    it "saves without the repository" do
      expect(source_project).not_to be_valid

      batch = GoodJob::Batch.enqueue(user: admin, source_project:) do
        described_class.perform_later(target_project_params: params, associations_to_copy: [:work_packages])
      end

      GoodJob.perform_inline
      batch.reload

      copied_project = batch.properties[:target_project]
      errors = batch.properties[:errors]

      expect(errors).to be_empty
      expect(copied_project).to be_valid
      expect(copied_project.repository).to be_nil
      expect(copied_project.enabled_module_names).not_to include "repository"
    end
  end

  describe "copy project fails with internal error" do
    let(:source_project) { create(:project) }

    before do
      allow(User).to receive(:current).and_return(admin)
      allow(Projects::CopyService).to receive(:new).and_return(->(*) { raise "Gen. Failure reporting for duty!" })
    end

    it "renders a error when unexpected errors occur" do
      copy_job = nil
      GoodJob::Batch.enqueue(user: admin, source_project:) do
        copy_job = described_class.perform_later(target_project_params: params, associations_to_copy: [:work_packages])
      end

      allow(ProjectMailer)
        .to receive(:copy_project_failed)
              .with(admin, source_project, "Copy", [I18n.t("copy_project.failed_internal")])
              .and_return(mail_double)

      GoodJob.perform_inline

      # expect to create a status
      expect(copy_job.job_status).to be_present
      expect(copy_job.job_status[:status]).to eq "failure"
      expect(copy_job.job_status[:message]).to include "Cannot copy project #{source_project.name}"
      expect(copy_job.job_status[:payload]).to eq("title" => "Copy project")
    end
  end

  context "when project has work package hierarchies with derived values" do
    shared_let(:source_project) { create(:project, name: "Source project") }

    before_all do
      set_factory_default(:project, source_project)
      set_factory_default(:project_with_types, source_project)
    end

    let_work_packages(<<~TABLE)
      hierarchy | work | remaining work | start date | end date   | scheduling mode
      parent    |   1h |             0h | 2024-01-23 | 2024-01-26 | automatic
        child   |   3h |           1.5h | 2024-01-23 | 2024-01-26 | manual
    TABLE

    before do
      WorkPackages::UpdateAncestorsService
        .new(user: admin, work_package: child)
        .call(%i[estimated_hours remaining_hours ignore_non_working_days])
    end

    it "copies the project without any errors (Bug #52384)" do
      allow(OpenProject.logger).to receive(:error)

      copy_job = nil
      batch = GoodJob::Batch.enqueue(user: admin, source_project:) do
        copy_job = described_class.perform_later(target_project_params: params, associations_to_copy: [:work_packages])
      end
      GoodJob.perform_inline
      batch.reload

      expect(copy_job.job_status.status).to eq "success"
      expect(batch.properties[:errors]).to be_empty
      expect(OpenProject.logger).not_to have_received(:error)

      copied_project = batch.properties[:target_project]
      expect_work_packages(copied_project.work_packages, <<~TABLE)
        hierarchy | work | remaining work | start date | end date   | scheduling mode
        parent    |   1h |             0h | 2024-01-23 | 2024-01-26 | automatic
          child   |   3h |           1.5h | 2024-01-23 | 2024-01-26 | manual
      TABLE
    end
  end

  describe "#perform" do
    let(:project) { create(:project, public: false) }
    let(:user) { create(:user) }
    let(:role) { create(:project_role, permissions: [:copy_projects]) }

    shared_context "on copy project" do
      before do
        GoodJob::Batch.enqueue(on_finish: SendCopyProjectStatusEmailJob, user:, source_project: project_to_copy) do
          described_class.perform_later(target_project_params: params, associations_to_copy: [:members])
        end

        perform_enqueued_jobs do # needed for the deliveries
          GoodJob.perform_inline
        end
      end
    end

    before do
      login_as(user)
      expect(User).to receive(:current=).with(user).at_least(:once)
    end

    describe "subproject" do
      let(:subproject) do
        create(:project, parent: project).tap do |p|
          create(:member, principal: user, roles: [role], project: p)
        end
      end

      subject(:copied_project) { Project.find_by(identifier: "copy") }

      describe "user without add_subprojects permission in parent" do
        include_context "on copy project" do
          let(:project_to_copy) { subproject }
        end

        it "copies the project without the parent being set" do
          expect(copied_project).not_to be_nil
          expect(copied_project.parent).to be_nil

          expect(subproject.reload.enabled_module_names).not_to be_empty
        end

        it "notifies the user of the success" do
          mail = ActionMailer::Base.deliveries
                                   .find { |m| m.message_id.start_with? "op.project-#{copied_project.id}" }

          expect(mail).to be_present
          expect(mail.subject).to eq "Created project #{subject.name}"
          expect(mail.to).to eq [user.mail]
        end
      end

      describe "user without add_subprojects permission in parent and when explicitly setting that parent" do
        let(:params) { { name: "Copy", identifier: "copy", parent_id: project.id } }

        include_context "on copy project" do
          let(:project_to_copy) { subproject }
        end

        it "does not copy the project" do
          expect(subject).to be_nil
        end

        it "notifies the user of that parent not being allowed" do
          mail = ActionMailer::Base.deliveries.first
          expect(mail).to be_present
          expect(mail.subject).to eq I18n.t("copy_project.failed", source_project_name: subproject.name)
          expect(mail.to).to eq [user.mail]
        end
      end

      describe "user with add_subprojects permission in parent" do
        let(:role_add_subproject) { create(:project_role, permissions: [:add_subprojects]) }
        let(:member_add_subproject) do
          create(:member,
                 user:,
                 project:,
                 roles: [role_add_subproject])
        end

        before do
          member_add_subproject
        end

        include_context "on copy project" do
          let(:project_to_copy) { subproject }
        end

        it "copies the project" do
          expect(subject).not_to be_nil
          expect(subject.parent).to eql(project)

          expect(subproject.reload.enabled_module_names).not_to be_empty
        end

        it "notifies the user of the success" do
          mail = ActionMailer::Base.deliveries
                                   .find { |m| m.message_id.start_with? "op.project-#{subject.id}" }

          expect(mail).to be_present
          expect(mail.subject).to eq "Created project #{subject.name}"
          expect(mail.to).to eq [user.mail]
        end
      end
    end
  end

  context "when project has relations" do
    shared_let(:source_project) { create(:project, name: "Source project") }

    before_all do
      set_factory_default(:project_with_types, source_project)
    end

    let_work_packages(<<~TABLE)
      hierarchy        | start date | end date   | scheduling mode
      automatic_parent | 2024-01-23 | 2024-01-26 | automatic
        child_ap       | 2024-01-23 | 2024-01-26 | manual
      manual_parent    | 2024-01-21 | 2024-01-28 | manual
        child_mp       | 2024-01-23 | 2024-01-26 | manual
    TABLE

    it "preserves hierarchy, dates and scheduling modes upon copying" do
      batch = GoodJob::Batch.enqueue(user: admin, source_project:) do
        described_class.perform_later(target_project_params: params, associations_to_copy: [:work_packages])
      end
      GoodJob.perform_inline

      copied_project = batch.reload.properties[:target_project]
      expect_work_packages(copied_project.work_packages, <<~TABLE)
        hierarchy        | start date | end date   | scheduling mode
        automatic_parent | 2024-01-23 | 2024-01-26 | automatic
          child_ap       | 2024-01-23 | 2024-01-26 | manual
        manual_parent    | 2024-01-21 | 2024-01-28 | manual
          child_mp       | 2024-01-23 | 2024-01-26 | manual
      TABLE
    end
  end

  # Bug #58342: combination of class attribute ActionMailer::Base.perform_deliveries that was not thread local, so was
  # reset to true before every request and job run, and using it to override Journal::NotificationConfiguration.active?
  # to decide to send notifications could cause notifications to be sent for adding as member despite selecting not to
  # do it.
  describe "sending notifications" do
    shared_let(:project) { create(:project) }
    shared_let(:user) { create(:user) }
    shared_let(:roles) { [create(:project_role)] }
    shared_let(:member) { create(:member, user:, project:, roles:) }

    def perform_the_job
      batch = GoodJob::Batch.enqueue(user: admin, source_project: project) do
        described_class.perform_later(target_project_params: params, associations_to_copy: [:members])
      end
      GoodJob.perform_inline
      batch.reload

      expect(batch).to be_succeeded
    end

    it "doesn't touch the perform_deliveries" do
      allow(ActionMailer::Base).to receive(:perform_deliveries=)

      perform_the_job

      expect(ActionMailer::Base).not_to have_received(:perform_deliveries=)
    end

    it "calls Members::CreateService without send_notifications override" do
      members_create_service = instance_double(Members::CreateService)
      allow(Members::CreateService).to receive(:new).and_return(members_create_service)
      allow(members_create_service).to receive(:call)

      perform_the_job

      expect(members_create_service).to have_received(:call).with(hash_excluding(:send_notifications))
    end
  end

  describe "skip_custom_field_validation parameter" do
    let(:source_project) { create(:project) }
    let(:job_args) do
      {
        target_project_params: { name: "Copy", identifier: "copy" },
        associations_to_copy: [],
        skip_custom_field_validation: true
      }
    end

    it "passes skip_custom_field_validation to CopyService" do
      allow(Projects::CopyService).to receive(:new).and_call_original
      GoodJob::Batch.enqueue(user: admin, source_project:) do
        described_class.perform_later(**job_args)
      end
      GoodJob.perform_inline

      expect(Projects::CopyService).to have_received(:new).with(
        hash_including(contract_options: { skip_custom_field_validation: true })
      )
    end
  end
end
