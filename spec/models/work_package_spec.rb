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

RSpec.describe WorkPackage do
  shared_let(:type) { create(:type_standard) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:project_archived) { create(:project, :archived) }
  shared_let(:status) { create(:status) }
  shared_let(:priority) { create(:priority) }
  shared_let(:user1) { create(:user) }

  before_all do
    set_factory_default(:user, user1)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
  end

  let(:stub_work_package) { build_stubbed(:work_package) }
  let(:stub_version) { build_stubbed(:version) }
  let(:stub_project) { build_stubbed(:project) }
  let(:user) { user1 }

  let(:work_package) do
    described_class.new.tap do |w|
      w.attributes = { project_id: project.id,
                       type_id: type.id,
                       author_id: user.id,
                       status_id: status.id,
                       priority:,
                       subject: "test_create",
                       description: "WorkPackage#create",
                       estimated_hours: "1h30" }
    end
  end

  describe "associations" do
    subject { work_package }

    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:type) }
    it { is_expected.to belong_to(:status) }
    it { is_expected.to belong_to(:author) }
    it { is_expected.to belong_to(:assigned_to).class_name("Principal").optional }
    it { is_expected.to belong_to(:responsible).class_name("Principal").optional }
    it { is_expected.to belong_to(:version).optional }
    it { is_expected.to belong_to(:priority).class_name("IssuePriority") }
    it { is_expected.to belong_to(:category).optional }
    it { is_expected.to have_many(:time_entries).dependent(:delete_all) }
    it { is_expected.to have_many(:file_links).dependent(:delete_all).class_name("Storages::FileLink") }
    it { is_expected.to have_many(:storages).through(:project) }
    it { is_expected.to have_and_belong_to_many(:changesets) }
    it { is_expected.to have_and_belong_to_many(:github_pull_requests) }
    it { is_expected.to have_many(:members).dependent(:destroy) }
    it { is_expected.to have_many(:member_principals).through(:members).class_name("Principal").source(:principal) }
    it { is_expected.to have_many(:meeting_agenda_items) }
    it { is_expected.to have_many(:meetings).through(:meeting_agenda_items).source(:meeting) }
  end

  describe ".new" do
    describe "type" do
      let(:type2) { create(:type) }

      before do
        project.types << type2
      end

      context "when no project chosen" do
        it "has no type set if no project was chosen" do
          expect(described_class.new.type)
            .to be_nil
        end
      end

      context "when project chosen" do
        it "has the provided type if one is provided" do
          expect(described_class.new(project:, type: type2).type)
            .to eql type2
        end
      end
    end
  end

  describe "create" do
    describe "#save" do
      subject { work_package.save }

      it { is_expected.to be_truthy }
    end

    describe "#estimated_hours" do
      before do
        work_package.save!
        work_package.reload
      end

      subject { work_package.estimated_hours }

      it { is_expected.to eq(1.5) }
    end

    describe "minimal" do
      let(:work_package_minimal) do
        described_class.new.tap do |w|
          w.attributes = { project_id: project.id,
                           type_id: type.id,
                           author_id: user.id,
                           status_id: status.id,
                           priority:,
                           subject: "test_create" }
        end
      end

      describe "save" do
        subject { work_package_minimal.save }

        it { is_expected.to be_truthy }
      end

      describe "description" do
        before do
          work_package_minimal.save!
          work_package_minimal.reload
        end

        subject { work_package_minimal.description }

        it { is_expected.to be_nil }
      end
    end

    describe "#assigned_to" do
      describe "group_assignment" do
        let(:group) { create(:group) }

        subject do
          create(:work_package,
                 assigned_to: group).assigned_to
        end

        it { is_expected.to eq(group) }
      end
    end
  end

  describe "#hide_attachments?" do
    subject { work_package.hide_attachments? }

    context "when project is present" do
      context "when project#deactivate_work_package_attachments is true" do
        before { work_package.project.deactivate_work_package_attachments = true }

        it { is_expected.to be_truthy }
      end

      context "when project#deactivate_work_package_attachments is false" do
        before { work_package.project.deactivate_work_package_attachments = false }

        it { is_expected.to be_falsy }
      end
    end

    context "when project is absent" do
      before { work_package.project = nil }

      context "if Setting.show_work_package_attachments is true", with_settings: { show_work_package_attachments: true } do
        it { is_expected.to be_falsy }
      end

      context "if Setting.show_work_package_attachments is false", with_settings: { show_work_package_attachments: false } do
        it { is_expected.to be_truthy }
      end
    end
  end

  describe "#category" do
    let(:user2) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }
    let(:category) do
      create(:category,
             project:,
             assigned_to: user2)
    end

    before do
      work_package.attributes = { category_id: category.id }
      work_package.save!
    end

    subject { work_package.assigned_to }

    it { is_expected.to eq(category.assigned_to) }
  end

  describe "responsible" do
    let(:group) { create(:group) }
    let!(:member) do
      create(:member,
             principal: group,
             project: work_package.project,
             roles: [create(:project_role)])
    end

    context "with group assigned" do
      before { work_package.responsible = group }

      it "is valid" do
        expect(work_package).to be_valid
      end
    end
  end

  describe "#assignable_versions" do
    let(:stub_version2) { build_stubbed(:version) }

    def stub_shared_versions(version = nil)
      versions = version ? [version] : []

      allow(stub_work_package.project).to receive(:assignable_versions).and_return(versions)
    end

    it "returns all the project's shared versions" do
      stub_shared_versions(stub_version)

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    it "returns the former version if the version changed" do
      stub_shared_versions

      stub_work_package.version = stub_version2

      allow(stub_work_package).to receive_messages(version_id_changed?: true, version_id_was: stub_version.id)
      allow(Version).to receive(:find_by).with(id: stub_version.id).and_return(stub_version)

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    it "returns the current version if the version did not change" do
      stub_shared_versions

      stub_work_package.version = stub_version

      allow(stub_work_package).to receive(:version_id_changed?).and_return false

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    context "with many versions" do
      let!(:work_package) do
        wp = create(:work_package,
                    project:,
                    version: version_current)
        # remove changes to version factored into
        # assignable_versions calculation
        wp.reload
        wp
      end
      let!(:version_current) do
        create(:version,
               status: "closed",
               project:)
      end
      let!(:version_open) do
        create(:version,
               status: "open",
               project:)
      end
      let!(:version_locked) do
        create(:version,
               status: "locked",
               project:)
      end
      let!(:version_closed) do
        create(:version,
               status: "closed",
               project:)
      end
      let!(:version_other_project) do
        create(:version,
               status: "open",
               project: create(:project))
      end

      it "returns all open versions of the project" do
        expect(work_package.assignable_versions)
          .to contain_exactly(version_current, version_open)
      end
    end
  end

  describe "#destroy" do
    let!(:time_entry1) do
      create(:time_entry,
             project:,
             work_package:)
    end
    let!(:time_entry2) do
      create(:time_entry,
             project:,
             work_package:)
    end

    before do
      work_package.destroy
    end

    describe "work package" do
      subject { described_class.find_by(id: work_package.id) }

      it { is_expected.to be_nil }
    end

    describe "time entries" do
      subject { TimeEntry.find_by(work_package_id: work_package.id) }

      it { is_expected.to be_nil }
    end
  end

  it_behaves_like "creates an audit trail on destroy" do
    subject { create(:work_package) }
  end

  describe "#done_ratio" do
    shared_let(:status_new) do
      create(:status,
             name: "New",
             is_default: true,
             is_closed: false,
             default_done_ratio: 50)
    end
    shared_let(:status_assigned) do
      create(:status,
             name: "Assigned",
             is_default: true,
             is_closed: false,
             default_done_ratio: 0)
    end
    shared_let(:work_package_new) do
      create(:work_package,
             status: status_new)
    end
    shared_let(:work_package_assigned) do
      create(:work_package,
             project: work_package_new.project,
             status: status_assigned,
             done_ratio: 30)
    end

    it "allows empty value" do
      work_package.done_ratio = ""
      expect(work_package).to be_valid
      expect(work_package.done_ratio).to be_nil
    end

    it "allows blank values" do
      work_package.done_ratio = "  "
      expect(work_package).to be_valid
      expect(work_package.done_ratio).to be_nil
    end

    it "allows nil value" do
      work_package.done_ratio = nil
      expect(work_package).to be_valid
      expect(work_package.done_ratio).to be_nil
    end

    it "allows values between 0 and 100" do
      work_package.done_ratio = 0
      expect(work_package).to be_valid
      work_package.done_ratio = 34
      expect(work_package).to be_valid
      work_package.done_ratio = 99
      expect(work_package).to be_valid

      work_package.done_ratio = "1"
      expect(work_package).to be_valid
      work_package.done_ratio = "100"
      expect(work_package).to be_valid
    end

    it "disallows values outside of the 0-100 range" do
      work_package.done_ratio = -1
      expect(work_package).not_to be_valid

      work_package.done_ratio = "-1%"
      expect(work_package.done_ratio).to eq(-1)
      expect(work_package).not_to be_valid

      work_package.done_ratio = 101.0
      expect(work_package.done_ratio).to eq(101)
      expect(work_package).not_to be_valid
    end

    it "allows floats and truncates them to integer" do
      work_package.done_ratio = 1.7
      expect(work_package).to be_valid
      expect(work_package.done_ratio).to eq(1)

      work_package.done_ratio = "1.7"
      expect(work_package).to be_valid
      expect(work_package.done_ratio).to eq(1)
    end

    it "allows percentage like '50%'" do
      work_package.done_ratio = "50%"
      expect(work_package).to be_valid
      expect(work_package.done_ratio).to eq(50)
    end

    it "disallows string values, that are not valid percentage values" do
      work_package.done_ratio = "abc"
      expect(work_package).not_to be_valid
    end

    describe "#value" do
      context "for work-based mode",
              with_settings: { work_package_done_ratio: "field" } do
        it "returns the value from work package field" do
          expect(work_package_new.done_ratio).to be_nil
          expect(work_package_assigned.done_ratio).to eq(30)
        end
      end

      context "for status-based mode",
              with_settings: { work_package_done_ratio: "status" } do
        it "uses the % Complete value from the work package status" do
          expect(work_package_new.done_ratio).to eq(status_new.default_done_ratio)
          expect(work_package_assigned.done_ratio).to eq(status_assigned.default_done_ratio)
        end
      end
    end

    describe "#update_done_ratio_from_status" do
      context "for work-based mode",
              with_settings: { work_package_done_ratio: "field" } do
        it "does not update the done ratio" do
          expect { work_package_new.update_done_ratio_from_status }
            .not_to change { work_package_new[:done_ratio] }
          expect { work_package_assigned.update_done_ratio_from_status }
            .not_to change { work_package_assigned[:done_ratio] }
        end
      end

      context "for status-based mode",
              with_settings: { work_package_done_ratio: "status" } do
        it "updates the done ratio without saving it" do
          expect { work_package_new.update_done_ratio_from_status }
            .to change { work_package_new[:done_ratio] }
                  .from(nil).to(50)
          expect { work_package_assigned.update_done_ratio_from_status }
            .to change { work_package_assigned[:done_ratio] }
                  .from(30).to(0)

          expect(work_package_new).to have_changes_to_save
        end
      end
    end
  end

  describe "#group_by" do
    shared_let(:type2) { create(:type) }
    shared_let(:priority2) { create(:priority) }
    shared_let(:project) { create(:project, types: [type, type2]) }
    shared_let(:version1) { create(:version, project:) }
    shared_let(:version2) { create(:version, project:) }
    shared_let(:category1) { create(:category, project:) }
    shared_let(:category2) { create(:category, project:) }
    shared_let(:user2) { create(:user) }

    shared_let(:work_package1) do
      create(:work_package,
             author: user1,
             assigned_to: user1,
             responsible: user1,
             project:,
             type:,
             priority:,
             version: version1,
             category: category1)
    end
    shared_let(:work_package2) do
      create(:work_package,
             author: user2,
             assigned_to: user2,
             responsible: user2,
             project:,
             type: type2,
             priority: priority2,
             version: version2,
             category: category2)
    end

    shared_examples_for "group by" do
      describe "size" do
        subject { groups.size }

        it { is_expected.to eq(2) }
      end

      describe "total" do
        subject { groups.inject(0) { |sum, group| sum + group["total"].to_i } }

        it { is_expected.to eq(2) }
      end
    end

    describe "by type" do
      let(:groups) { described_class.by_type(project) }

      it_behaves_like "group by"
    end

    describe "by version" do
      let(:groups) { described_class.by_version(project) }

      it_behaves_like "group by"
    end

    describe "by priority" do
      let(:groups) { described_class.by_priority(project) }

      it_behaves_like "group by"
    end

    describe "by category" do
      let(:groups) { described_class.by_category(project) }

      it_behaves_like "group by"
    end

    describe "by assigned to" do
      let(:groups) { described_class.by_assigned_to(project) }

      it_behaves_like "group by"
    end

    describe "by responsible" do
      let(:groups) { described_class.by_responsible(project) }

      it_behaves_like "group by"
    end

    describe "by author" do
      let(:groups) { described_class.by_author(project) }

      it_behaves_like "group by"
    end

    describe "by project" do
      shared_let(:project2) { create(:project, parent: project) }
      shared_let(:work_package3) { create(:work_package, project: project2) }
      let(:groups) { described_class.by_author(project) }

      it_behaves_like "group by"
    end
  end

  describe "#recently_updated" do
    let!(:work_package1) { create(:work_package) }
    let!(:work_package2) { create(:work_package) }

    before do
      without_timestamping do
        work_package1.updated_at = 1.minute.ago
        work_package1.save!
      end
    end

    describe "limit" do
      subject { described_class.recently_updated.limit(1).first }

      it { is_expected.to eq(work_package2) }
    end
  end

  describe "#on_active_project" do
    shared_let(:work_package) { create(:work_package, project:) }

    subject { described_class.on_active_project.length }

    context "with one work package in active projects" do
      it { is_expected.to eq(1) }

      context "and one work package in archived projects" do
        shared_let(:work_package_in_archived_project) do
          create(:work_package, project: project_archived)
        end

        it { is_expected.to eq(1) }
      end
    end
  end

  describe "#with_author" do
    shared_let(:work_package) { create(:work_package, project:, author: user1) }

    subject { described_class.with_author(user1).length }

    context "with one work package in active projects" do
      it { is_expected.to eq(1) }

      context "and one work package in archived projects" do
        shared_let(:work_package_in_archived_project) do
          create(:work_package, project: project_archived, author: user1)
        end

        it { is_expected.to eq(2) }
      end
    end
  end

  describe "#add_time_entry" do
    it "returns a new time entry" do
      expect(stub_work_package.add_time_entry).to be_a TimeEntry
    end

    it "has already the project assigned" do
      stub_work_package.project = stub_project

      expect(stub_work_package.add_time_entry.project).to eq(stub_project)
    end

    it "has already the work_package assigned" do
      expect(stub_work_package.add_time_entry.work_package).to eq(stub_work_package)
    end

    it "returns an unsaved entry" do
      expect(stub_work_package.add_time_entry).to be_new_record
    end
  end

  describe ".allowed_target_project_on_move" do
    let(:permissions) { [:move_work_packages] }
    let(:user) do
      create(:user, member_with_permissions: { project => permissions })
    end

    context "when having the move_work_packages permission" do
      it "returns the project" do
        expect(described_class.allowed_target_projects_on_move(user))
          .to contain_exactly(project)
      end
    end

    context "when lacking the move_work_packages permission" do
      let(:permissions) { [] }

      it "does not return the project" do
        expect(described_class.allowed_target_projects_on_move(user))
          .to be_empty
      end
    end
  end

  describe ".allowed_target_project_on_create" do
    let(:permissions) { [:add_work_packages] }
    let(:user) do
      create(:user, member_with_permissions: { project => permissions })
    end

    context "when having the add_work_packages permission" do
      it "returns the project" do
        expect(described_class.allowed_target_projects_on_create(user))
          .to contain_exactly(project)
      end
    end

    context "when lacking the add_work_packages permission" do
      let(:permissions) { [] }

      it "does not return the project" do
        expect(described_class.allowed_target_projects_on_create(user))
          .to be_empty
      end
    end
  end

  describe "#duration" do
    context "when not setting a value" do
      it "is nil" do
        expect(work_package.duration).to be_nil
      end
    end

    context "when setting the value" do
      before do
        work_package.duration = 5
      end

      it "is the value" do
        expect(work_package.duration).to eq(5)
      end
    end
  end

  describe "changed_since" do
    shared_let(:work_package) do
      Timecop.travel(5.hours.ago) do
        create(:work_package, project:)
      end
    end

    subject { described_class.changed_since(since) }

    describe "null" do
      let(:since) { nil }

      it { expect(subject).to contain_exactly(work_package) }
    end

    describe "now" do
      let(:since) { DateTime.now }

      it { expect(subject).to be_empty }
    end

    describe "work package update" do
      let(:since) { work_package.reload.updated_at }

      it { expect(subject).to contain_exactly(work_package) }
    end
  end

  describe "#ignore_non_working_days" do
    context "for a new record" do
      it "is false" do
        expect(described_class.new.ignore_non_working_days)
          .to be false
      end
    end
  end

  context "when destroying with agenda items" do
    shared_let(:work_package) do
      create(:work_package, project:, type:, status:, priority:)
    end

    shared_let(:meeting_agenda_items) { create_list(:meeting_agenda_item, 3, work_package:) }
    shared_let(:other_agenda_item) { create(:meeting_agenda_item, work_package_id: create(:work_package).id) }
    shared_let(:other_meeting) { other_agenda_item.meeting }
    let(:latest_journals) do
      Journal
        .select("DISTINCT ON (journable_id) *")
        .where(journable_type: "Meeting", journable_id: meeting_agenda_items.pluck(:meeting_id))
        .order("journable_id, updated_at DESC")
    end

    subject { work_package.destroy }

    before do
      work_package.save
      Meeting.find_each(&:save_journals)
    end

    it "dissociates the agenda items" do
      expect { subject }
        .to change { MeetingAgendaItem.find(meeting_agenda_items).pluck(:work_package_id) }
              .from(Array.new(3, work_package.id))
              .to(Array.new(3, nil))
    end

    it "does not affect other agenda items" do
      expect { subject }.not_to change(other_agenda_item, :reload)
    end

    it "updates the agenda item journal" do
      expect { subject }
        .to change {
          Journal::MeetingAgendaItemJournal
            .where(agenda_item: meeting_agenda_items)
            .pluck(:work_package_id)
        }
              .from(Array.new(3, work_package.id))
              .to(Array.new(3, nil))
    end

    it "does not affect the agenda item journal" do
      expect { subject }
        .not_to change {
          Journal::MeetingAgendaItemJournal
            .find_by(agenda_item: other_agenda_item)
            .work_package_id
        }
    end
  end

  describe "#remaining_hours" do
    it "allows empty value" do
      work_package.remaining_hours = ""
      expect(work_package).to be_valid
      expect(work_package.remaining_hours).to be_nil
    end

    it "allows blank values" do
      work_package.remaining_hours = "  "
      expect(work_package).to be_valid
      expect(work_package.remaining_hours).to be_nil
    end

    it "allows nil value" do
      work_package.remaining_hours = nil
      expect(work_package).to be_valid
      expect(work_package.remaining_hours).to be_nil
    end

    it "allows values greater than or equal to 0" do
      work_package.remaining_hours = "0"
      expect(work_package).to be_valid

      work_package.remaining_hours = "1"
      expect(work_package).to be_valid
    end

    it "disallows negative values" do
      work_package.remaining_hours = "-1"
      expect(work_package).not_to be_valid

      work_package.remaining_hours = "-1h"
      expect(work_package.remaining_hours).to eq(-1)
      expect(work_package).not_to be_valid
    end

    it "disallows string values, that are not numbers" do
      work_package.remaining_hours = "abc"
      expect(work_package).not_to be_valid
    end

    it "allows non-integers" do
      work_package.remaining_hours = "1.3"
      expect(work_package).to be_valid
    end

    it "allows hours like '1h06'" do
      work_package.remaining_hours = "1h06"
      expect(work_package).to be_valid
      expect(work_package.remaining_hours).to eq(1.1)
    end

    it "allows hours like '1h 24m'" do
      work_package.remaining_hours = "1h 24m"
      expect(work_package).to be_valid
      expect(work_package.remaining_hours).to eq(1.4)
    end

    it "allows hours like '3d 1.5h 30m'" do
      work_package.remaining_hours = "3d 1h 30m"
      expect(work_package).to be_valid
      expect(work_package.remaining_hours).to eq((3 * 8) + 1.5)
    end
  end
end
