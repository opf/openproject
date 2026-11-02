# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Milestone services" do # rubocop:disable RSpec/DescribeClass
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:manager) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs manage_test_milestones view_work_packages] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }

  describe TestManagement::Milestones::CreateService do
    it "creates an open milestone with links and the author" do
      work_package = create(:work_package, project:)
      call = described_class.new(user: manager).call(project:, name: "Release 2.0", due_date: "2026-12-01",
                                                     work_package_ids: "##{work_package.id}")

      expect(call).to be_success
      expect(call.result).to have_attributes(status: "open", created_by: manager, due_date: Date.new(2026, 12, 1))
      expect(call.result.work_packages).to contain_exactly(work_package)
    end

    it "fails without permission" do
      call = described_class.new(user: viewer).call(project:, name: "Release 2.0")
      expect(call).to be_failure
      expect(TestManagement::Milestone.count).to eq(0)
    end
  end

  describe TestManagement::Milestones::UpdateService do
    it "replaces visible links but keeps links the user cannot see" do
      milestone = create(:tm_milestone, project:)
      visible = create(:work_package, project:)
      hidden_project = create(:project, enabled_module_names: %i[work_package_tracking])
      hidden = create(:work_package, project: hidden_project)
      create(:tm_milestone_work_package, milestone:, work_package: visible)
      create(:tm_milestone_work_package, milestone:, work_package: hidden)
      replacement = create(:work_package, project:)

      call = described_class.new(user: manager, model: milestone).call(work_package_ids: [replacement.id.to_s])

      expect(call).to be_success
      expect(milestone.reload.work_packages).to contain_exactly(replacement, hidden)
    end
  end

  describe "transitions" do
    let(:milestone) { create(:tm_milestone, project:) }

    def transition(service, user: manager) = service.new(user:, model: milestone).call

    it "starts, completes and reopens (back to started)" do
      expect(transition(TestManagement::Milestones::StartService)).to be_success
      expect(milestone.reload).to have_attributes(status: "started", start_date: Date.current)
      expect(milestone.started_at).to be_present

      expect(transition(TestManagement::Milestones::StartService)).to be_failure
      expect(milestone.errors.details[:base]).to include(error: :tm_invalid_transition)
      expect(milestone.errors.full_messages.join).to include("not possible in the milestone's current status")

      expect(transition(TestManagement::Milestones::CompleteService)).to be_success
      expect(milestone.reload).to have_attributes(status: "completed", completed_at: be_present)

      expect(transition(TestManagement::Milestones::ReopenService)).to be_success
      expect(milestone.reload).to have_attributes(status: "started", completed_at: nil)
    end

    it "reopens a never started milestone as open" do
      transition(TestManagement::Milestones::CompleteService)
      transition(TestManagement::Milestones::ReopenService)
      expect(milestone.reload.status).to eq("open")
    end

    it "needs manage_test_milestones" do
      call = transition(TestManagement::Milestones::CompleteService, user: viewer)
      expect(call).to be_failure
      expect(milestone.reload.status).to eq("open")
    end

    it "deletes and keeps the runs" do
      run = create(:tm_test_run, project:, milestone:)
      expect(transition(TestManagement::Milestones::DeleteService)).to be_success
      expect(TestManagement::Milestone.exists?(milestone.id)).to be(false)
      expect(run.reload.milestone_id).to be_nil
    end
  end
end
