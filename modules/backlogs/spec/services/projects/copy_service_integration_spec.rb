# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Projects::CopyService, "integration", type: :model do
  shared_let(:role) do
    create(:project_role,
           permissions: %i[copy_projects])
  end
  shared_let(:source) do
    create(:project,
           name: "Source Project Name",
           enabled_module_names: %i[work_package_tracking backlogs])
  end
  shared_let(:current_user) do
    create(:user,
           member_with_roles: { source => role })
  end

  let(:instance) { described_class.new(source:, user: current_user) }
  let(:target_project_params) do
    { name: "Target Project Name", identifier: "some-identifier" }
  end
  let(:params) do
    { target_project_params:, send_notifications: false }
  end
  let(:project_copy) { subject.result }

  describe ".call" do
    subject { instance.call(params) }

    describe "#sprint_sharing setting" do
      context "with an ee license for sprint sharing", with_ee: %i[sprint_sharing] do
        context "when the source project is set to receive" do
          before do
            source.sprint_sharing = Projects::SprintSettings::RECEIVE_SHARED
            source.save!
          end

          it "copies the backlog sharing setting" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSettings::RECEIVE_SHARED
          end
        end

        context "when the source project is set to share with subprojects" do
          before do
            source.sprint_sharing = Projects::SprintSettings::SHARE_SUBPROJECTS
            source.save!
          end

          it "copies the backlog sharing setting" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSettings::SHARE_SUBPROJECTS
          end
        end

        context "when the source project is set to not share" do
          before do
            source.sprint_sharing = Projects::SprintSettings::NO_SHARING
            source.save!
          end

          it "copies the backlog sharing setting" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSettings::NO_SHARING
          end
        end

        context "when the source project is set to share with all" do
          before do
            source.sprint_sharing = Projects::SprintSettings::SHARE_ALL_PROJECTS
            source.save!
          end

          it "does not copy the setting as that would result in two projects sharing with all" do
            expect(subject).to be_success
            expect(project_copy.sprint_sharing).to eq Projects::SprintSettings::NO_SHARING
          end
        end
      end

      context "without an ee license for sprint sharing", with_ee: %i[] do
        Projects::SprintSettings::SPRINT_SHARING_MODES.each do |mode|
          context "when the source project is set to #{mode}" do
            before do
              source.sprint_sharing = mode
              source.save!
            end

            it "copies the backlog sharing setting" do
              expect(subject).to be_success
              expect(project_copy.sprint_sharing).to eq Projects::SprintSettings::NO_SHARING
            end
          end
        end
      end
    end
  end

  describe "sprint copying", with_ee: %i[sprint_sharing] do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[sprints] }
    end
    # Scoped to this describe so each context picks its sharing mode via
    # +sprint_sharing+ instead of mutating the outer shared_let project.
    let(:sprint_sharing) { Projects::SprintSettings::NO_SHARING }
    let(:source) do
      create(:project,
             name: "Source Project Name",
             enabled_module_names: %i[work_package_tracking backlogs],
             sprint_sharing:)
    end
    let(:sprint_project) { source }
    let!(:source_sprint) { create(:sprint, project: sprint_project, name: "Sprint A") }

    subject { instance.call(params) }

    shared_examples "copies sprints decoupled from the source" do
      it "copies owned sprints to the target, decoupled from the source" do
        expect(subject).to be_success

        expect(project_copy.sprints.pluck(:name)).to contain_exactly("Sprint A")
        copied_sprint = project_copy.sprints.first
        expect(copied_sprint.id).not_to eq(source_sprint.id)
        expect(copied_sprint.project).to eq(project_copy)

        copied_sprint.update!(name: "Renamed Copy")
        expect(source_sprint.reload.name).to eq("Sprint A")
      end

      it "maps the source sprint id to the new sprint id in state" do
        expect(subject).to be_success
        expect(subject.state.sprint_id_lookup[source_sprint.id]).to eq(project_copy.sprints.first.id)
      end
    end

    context "when source has NO_SHARING" do
      let(:sprint_sharing) { Projects::SprintSettings::NO_SHARING }

      include_examples "copies sprints decoupled from the source"
    end

    context "when source has SHARE_SUBPROJECTS" do
      let(:sprint_sharing) { Projects::SprintSettings::SHARE_SUBPROJECTS }

      include_examples "copies sprints decoupled from the source"
    end

    context "when source has SHARE_ALL_PROJECTS" do
      let(:sprint_sharing) { Projects::SprintSettings::SHARE_ALL_PROJECTS }

      # The project copy is set to NO_SHARING in the
      # OpenProject::Backlogs::Patches::CopyServicePatch#clean_settings_attributes!,
      # hence it has to have it's own sprints copied.
      include_examples "copies sprints decoupled from the source"
    end

    context "when source has RECEIVE_SHARED" do
      let(:sprint_sharing) { Projects::SprintSettings::RECEIVE_SHARED }
      let(:sprint_project) do
        create(:project,
               enabled_module_names: %i[work_package_tracking backlogs],
               sprint_sharing: Projects::SprintSettings::SHARE_ALL_PROJECTS)
      end

      it "does not copy the shared sprint it only receives" do
        expect(subject).to be_success
        expect(project_copy.sprints).to be_empty
      end

      context "and work packages are copied along" do
        let(:params) do
          { target_project_params:, send_notifications: false, only: %w[work_packages sprints] }
        end
        let!(:work_package) { create(:work_package, project: source, subject: "On received") }

        before { work_package.update_column(:sprint_id, source_sprint.id) }

        it "keeps the copied work package on the original shared sprint" do
          expect(subject).to be_success

          copied = project_copy.work_packages.find_by(subject: "On received")
          expect(copied.sprint_id).to eq(source_sprint.id)
        end
      end
    end

    context "when a RECEIVE_SHARED source still owns a sprint (stale data)" do
      # source_sprint is owned by source (created through the factory, which
      # bypasses the create contract that forbids sprints on a receiving project).
      let(:sprint_sharing) { Projects::SprintSettings::RECEIVE_SHARED }

      include_examples "copies sprints decoupled from the source"
    end

    context "when the source sprint has goals" do
      let!(:owned_goal) do
        create(:sprint_goal, sprint: source_sprint, project: source, text: "Ship it")
      end

      it "copies the owned goal onto the copied sprint, remapped to the copy" do
        expect(subject).to be_success

        copied_sprint = project_copy.sprints.find_by(name: "Sprint A")
        expect(copied_sprint.goals.pluck(:text, :project_id))
          .to contain_exactly(["Ship it", project_copy.id])
      end

      it "does not copy goals owned by other projects" do
        other_project = create(:project)
        create(:sprint_goal, sprint: source_sprint, project: other_project, text: "Not mine")

        expect(subject).to be_success

        copied_sprint = project_copy.sprints.find_by(name: "Sprint A")
        expect(copied_sprint.goals.pluck(:text)).to contain_exactly("Ship it")
      end

      it "leaves the goal on the source sprint intact" do
        expect(subject).to be_success

        expect(source_sprint.reload.goals.pluck(:text, :project_id))
          .to contain_exactly(["Ship it", source.id])
      end
    end
  end

  describe "shared sprint preservation", with_ee: %i[sprint_sharing] do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[work_packages sprints] }
    end
    let(:sprint_sharing) { Projects::SprintSettings::NO_SHARING }
    let(:source) do
      create(:project,
             name: "Source Project Name",
             enabled_module_names: %i[work_package_tracking backlogs],
             sprint_sharing:)
    end
    let!(:work_package) { create(:work_package, project: source, subject: "On shared") }

    subject { instance.call(params) }

    def copied_wp(subject_text)
      project_copy.work_packages.find_by(subject: subject_text)
    end

    context "when the sprint is shared with all projects and the copy receives it" do
      let(:sprint_sharing) { Projects::SprintSettings::RECEIVE_SHARED }
      let!(:sharer) do
        create(:project,
               enabled_module_names: %i[work_package_tracking backlogs],
               sprint_sharing: Projects::SprintSettings::SHARE_ALL_PROJECTS)
      end
      let!(:shared_sprint) { create(:sprint, project: sharer, name: "Global Sprint") }

      before { work_package.update_column(:sprint_id, shared_sprint.id) }

      it "preserves the assignment to the shared sprint" do
        expect(subject).to be_success
        expect(copied_wp("On shared").sprint_id).to eq(shared_sprint.id)
      end

      it "does not copy the shared sprint into the target" do
        expect(subject).to be_success
        expect(project_copy.sprints).to be_empty
      end
    end

    context "when the sprint is shared through an ancestor" do
      let!(:ancestor) do
        create(:project,
               enabled_module_names: %i[work_package_tracking backlogs],
               sprint_sharing: Projects::SprintSettings::SHARE_SUBPROJECTS)
      end
      let(:source) do
        create(:project,
               parent: ancestor,
               enabled_module_names: %i[work_package_tracking backlogs],
               sprint_sharing: Projects::SprintSettings::RECEIVE_SHARED)
      end
      let!(:shared_sprint) { create(:sprint, project: ancestor, name: "Subtree Sprint") }

      before { work_package.update_column(:sprint_id, shared_sprint.id) }

      it "preserves the assignment when the copy stays within the sharing subtree" do
        # The copy inherits the source's parent, so it remains a descendant of
        # the sharing ancestor and keeps receiving the sprint.
        expect(subject).to be_success
        expect(copied_wp("On shared").sprint_id).to eq(shared_sprint.id)
      end

      context "and the copy is moved out of the subtree" do
        let(:target_project_params) do
          { name: "Target Project Name", identifier: "some-identifier", parent_id: nil }
        end

        it "keeps the assignment to the borrowed sprint" do
          # The copy no longer receives the sprint through sharing, but the
          # borrowed association is valid state and is carried over as-is.
          expect(subject).to be_success
          expect(copied_wp("On shared").sprint_id).to eq(shared_sprint.id)
        end
      end
    end
  end

  describe "work package sprint reassignment" do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[work_packages sprints] }
    end
    let(:other_project) do
      create(:project, enabled_module_names: %i[work_package_tracking backlogs])
    end
    let!(:owned_sprint) { create(:sprint, project: source, name: "Owned Sprint") }
    let!(:shared_sprint) { create(:sprint, project: other_project, name: "Shared Sprint") }
    let!(:wp_owned1) { create(:work_package, project: source, subject: "In owned") }
    let!(:wp_owned2) { create(:work_package, project: source, subject: "Second in owned") }
    let!(:wp_in_shared) { create(:work_package, project: source, subject: "In shared") }
    let!(:wp_inbox1) { create(:work_package, project: source, subject: "Inbox 1") }
    let!(:wp_inbox2) { create(:work_package, project: source, subject: "Inbox 2") }
    let!(:wp_inbox3) { create(:work_package, project: source, subject: "Inbox 3") }

    subject { instance.call(params) }

    before do
      wp_owned1.update_columns(sprint_id: owned_sprint.id, position: 2)
      wp_owned2.update_columns(sprint_id: owned_sprint.id, position: 1)
      wp_in_shared.update_column(:sprint_id, shared_sprint.id)
      wp_inbox1.update_column(:position, 3)
      wp_inbox2.update_column(:position, 1)
      wp_inbox3.update_column(:position, 2)
    end

    def copied_wp(subject_text)
      project_copy.work_packages.find_by(subject: subject_text)
    end

    it "assigns the copied work package to the copied sprint for owned sprints" do
      expect(subject).to be_success

      copied = copied_wp("In owned")
      expect(copied.sprint.name).to eq("Owned Sprint")
      expect(copied.sprint_id).not_to eq(owned_sprint.id)
      expect(copied.sprint.project).to eq(project_copy)
    end

    it "keeps the sprint when it belongs to another project" do
      # A work package can legitimately borrow a sprint from another project,
      # e.g. after being moved between projects; the copy keeps that link.
      expect(subject).to be_success

      expect(copied_wp("In shared").sprint_id).to eq(shared_sprint.id)
    end

    it "does not add the copied work package to the source sprint" do
      expect(subject).to be_success

      expect(owned_sprint.reload.work_packages.pluck(:subject)).to contain_exactly("In owned", "Second in owned")
    end

    it "preserves the position of each copied work package" do
      expect(subject).to be_success

      # Sprint
      expect(copied_wp("In owned").position).to eq(2)
      expect(copied_wp("Second in owned").position).to eq(1)
      # Backlog Inbox
      expect(copied_wp("Inbox 1").position).to eq(3)
      expect(copied_wp("Inbox 2").position).to eq(1)
      expect(copied_wp("Inbox 3").position).to eq(2)
    end

    context "when sprints are not copied" do
      let(:params) do
        { target_project_params:, send_notifications: false, only: %w[work_packages] }
      end

      it "clears the sprint rather than keeping the source sprint id" do
        expect(subject).to be_success

        expect(copied_wp("In owned").sprint_id).to be_nil
      end
    end
  end

  describe "backlog bucket copying" do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[backlog_buckets] }
    end
    let!(:source_bucket) { create(:backlog_bucket, project: source, name: "Bucket A") }

    subject { instance.call(params) }

    it "copies owned backlog buckets to the target, decoupled from the source" do
      expect(subject).to be_success

      expect(project_copy.backlog_buckets.pluck(:name)).to contain_exactly("Bucket A")
      copied_bucket = project_copy.backlog_buckets.first
      expect(copied_bucket.id).not_to eq(source_bucket.id)
      expect(copied_bucket.project).to eq(project_copy)

      copied_bucket.update!(name: "Renamed Copy")
      expect(source_bucket.reload.name).to eq("Bucket A")
    end
  end

  describe "work package backlog bucket reassignment" do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[work_packages backlog_buckets] }
    end
    let!(:source_bucket) { create(:backlog_bucket, project: source, name: "Bucket A") }
    let!(:wp_in_bucket) { create(:work_package, project: source, subject: "In bucket") }

    subject { instance.call(params) }

    before do
      wp_in_bucket.update_column(:backlog_bucket_id, source_bucket.id)
    end

    def copied_wp(subject_text)
      project_copy.work_packages.find_by(subject: subject_text)
    end

    it "assigns the copied work package to the copied backlog bucket" do
      expect(subject).to be_success

      copied = copied_wp("In bucket")
      expect(copied.backlog_bucket.name).to eq("Bucket A")
      expect(copied.backlog_bucket_id).not_to eq(source_bucket.id)
      expect(copied.backlog_bucket.project).to eq(project_copy)
    end

    it "does not add the copied work package to the source backlog bucket" do
      expect(subject).to be_success

      expect(source_bucket.reload.work_packages.pluck(:subject)).to contain_exactly("In bucket")
    end

    context "when the buckets are not copied" do
      let(:params) do
        { target_project_params:, send_notifications: false, only: %w[work_packages] }
      end

      it "clears the backlog bucket rather than keeping the source id" do
        expect(subject).to be_success

        expect(copied_wp("In bucket").backlog_bucket_id).to be_nil
      end
    end
  end

  describe "query filter remapping", with_ee: %i[sprint_sharing] do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[members work_packages sprints backlog_buckets queries] }
    end
    let!(:source_sprint) { create(:sprint, project: source, name: "Sprint A") }
    let!(:source_bucket) { create(:backlog_bucket, project: source, name: "Bucket A") }
    let!(:sprint_query) do
      build(:query, project: source, name: "By sprint").tap do |q|
        q.add_filter("sprint_id", "=", [source_sprint.id.to_s])
        q.save!(validate: false)
        create(:view_work_packages_table, query: q)
      end
    end
    let!(:bucket_query) do
      build(:query, project: source, name: "By bucket").tap do |q|
        q.add_filter("backlog_bucket_id", "=", [source_bucket.id.to_s])
        q.save!(validate: false)
        create(:view_work_packages_table, query: q)
      end
    end

    subject { instance.call(params) }

    def copied_filter(query_name, filter_name)
      query = project_copy.queries.find_by(name: query_name)
      query.filters.find { |filter| filter.name.to_sym == filter_name }
    end

    it "remaps the sprint_id filter to the copied sprint" do
      expect(subject).to be_success

      copied_sprint = project_copy.sprints.find_by(name: "Sprint A")
      expect(copied_filter("By sprint", :sprint_id).values).to eq [copied_sprint.id.to_s]
    end

    it "remaps the backlog_bucket_id filter to the copied bucket" do
      expect(subject).to be_success

      copied_bucket = project_copy.backlog_buckets.find_by(name: "Bucket A")
      expect(copied_filter("By bucket", :backlog_bucket_id).values).to eq [copied_bucket.id.to_s]
    end
  end

  describe "when a sprint cannot be copied", with_ee: %i[sprint_sharing] do
    let(:admin) { create(:admin) }
    let(:instance) { described_class.new(source:, user: admin) }
    let(:params) do
      { target_project_params:, send_notifications: false, only: %w[sprints] }
    end
    let!(:valid_sprint) { create(:sprint, project: source, name: "Valid") }
    let!(:invalid_sprint) { create(:sprint, project: source, name: "Invalid") }

    subject { instance.call(params) }

    before do
      # Simulate stale data whose copy fails validation (blank name). The copy
      # should stay tolerant and skip it rather than aborting.
      invalid_sprint.update_column(:name, "")
    end

    it "still copies the valid sprints" do
      expect(subject).to be_success
      expect(project_copy.sprints.pluck(:name)).to contain_exactly("Valid")
    end

    it "surfaces the skipped sprint as an error instead of dropping it silently" do
      expect(subject.errors.full_messages).not_to be_empty
    end
  end
end
