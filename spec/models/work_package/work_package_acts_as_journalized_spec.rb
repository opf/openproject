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
  describe "#journal" do
    let(:type) { create(:type) }
    let(:project) do
      create(:project,
             types: [type])
    end
    let(:status) { create(:default_status) }
    let(:priority) { create(:priority) }
    let!(:work_package) do
      User.execute_as current_user do
        create(:work_package,
               project_id: project.id,
               type:,
               description: "Description",
               priority:,
               status:,
               duration: 1)
      end
    end
    let(:other_work_package) { build_stubbed(:work_package) }

    current_user { create(:user) }

    context "for work package creation" do
      it { expect(Journal.for_work_package.count).to eq(1) }

      it "has a journal entry" do
        expect(Journal.for_work_package.first.journable).to eq(work_package)
      end

      it "notes the changes to subject" do
        expect(work_package.last_journal.details[:subject])
          .to contain_exactly(nil, work_package.subject)
      end

      it "notes the changes to project" do
        expect(work_package.last_journal.details[:project_id])
          .to contain_exactly(nil, work_package.project_id)
      end

      it "notes the description" do
        expect(work_package.last_journal.details[:description])
          .to contain_exactly(nil, work_package.description)
      end

      it "notes the scheduling mode" do
        expect(work_package.last_journal.details[:schedule_manually])
          .to contain_exactly(nil, false)
      end

      it "has the timestamp of the work package update time for created_at" do
        expect(work_package.last_journal.created_at)
          .to eql(work_package.reload.updated_at)
      end

      it "has the updated_at of the work package as the lower bound for validity_period and no upper bound" do
        expect(work_package.last_journal.validity_period)
          .to eql(work_package.reload.updated_at...)
      end
    end

    context "when nothing is changed" do
      it { expect { work_package.save! }.not_to change(Journal, :count) }

      it "does not update the updated_at time of the work package" do
        expect { work_package.save! }.not_to change(work_package, :updated_at)
      end
    end

    context "for different newlines", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:description) { "Description\n\nwith newlines\n\nembedded" }
      let(:changed_description) { description.gsub("\n", "\r\n") }
      let!(:work_package1) do
        create(:work_package,
               project_id: project.id,
               type:,
               description:,
               priority:)
      end

      before do
        work_package1.description = changed_description
      end

      context "when a new journal is created tracking a simultaneously applied change" do
        before do
          work_package1.subject += "changed"
          work_package1.save!
        end

        describe "does not track the changed newline characters" do
          subject { work_package1.last_journal.data.description }

          it { is_expected.to eq(description) }
        end

        describe "tracks only the other change" do
          subject { work_package1.last_journal.details }

          it { is_expected.to have_key :subject }
          it { is_expected.not_to have_key :description }
        end
      end

      context "when there is a legacy journal containing non-escaped newlines" do
        let!(:work_package1) do
          create(:work_package,
                 journals: {
                   5.minutes.ago => { description: },
                   3.minutes.ago => { description: changed_description }
                 })
        end

        it "does not track the change to the newline characters" do
          expect(work_package1.reload.last_journal.details).not_to have_key :description
        end
      end
    end

    describe "on work package change without aggregation", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:parent_work_package) do
        create(:work_package,
               project_id: project.id,
               type:,
               priority:)
      end
      let(:type2) { create(:type) }
      let(:status2) { create(:status) }
      let(:priority2) { create(:priority) }

      before do
        project.types << type2

        work_package.subject = "changed"
        work_package.description = "changed"
        work_package.type = type2
        work_package.status = status2
        work_package.priority = priority2
        work_package.start_date = Date.new(2013, 1, 24)
        work_package.due_date = Date.new(2013, 1, 31)
        work_package.duration = 8
        work_package.estimated_hours = 40.0
        work_package.assigned_to = User.current
        work_package.responsible = User.current
        work_package.parent = parent_work_package
        work_package.schedule_manually = true

        work_package.save!
      end

      context "for last created journal" do
        subject { work_package.last_journal.details }

        it "contains all changes" do
          %i(subject description type_id status_id priority_id
             start_date due_date estimated_hours assigned_to_id
             responsible_id parent_id schedule_manually duration).each do |a|
            expect(subject).to have_key(a.to_s), "Missing change for #{a}"
          end
        end
      end

      shared_examples_for "old value" do
        subject { work_package.last_journal.old_value_for(property) }

        it { is_expected.to eq(expected_value) }
      end

      shared_examples_for "new value" do
        subject { work_package.last_journal.new_value_for(property) }

        it { is_expected.to eq(expected_value) }
      end

      describe "journaled value for" do
        describe "description" do
          let(:property) { "description" }

          context "for old value" do
            let(:expected_value) { "Description" }

            it_behaves_like "old value"
          end

          context "for new value" do
            let(:expected_value) { "changed" }

            it_behaves_like "new value"
          end
        end

        describe "schedule_manually" do
          let(:property) { "schedule_manually" }

          context "for old value" do
            let(:expected_value) { false }

            it_behaves_like "old value"
          end

          context "for new value" do
            let(:expected_value) { true }

            it_behaves_like "new value"
          end
        end

        describe "duration" do
          let(:property) { "duration" }

          context "for old value" do
            let(:expected_value) { 1 }

            it_behaves_like "old value"
          end

          context "for new value" do
            let(:expected_value) { 8 }

            it_behaves_like "new value"
          end
        end
      end

      describe "adding journal with a missing journal and an existing journal" do
        before do
          allow(WorkPackages::UpdateContract).to receive(:new).and_return(NoopContract.new)
          service = WorkPackages::UpdateService.new(user: current_user, model: work_package)
          service.call(journal_notes: "note to be deleted", send_notifications: false)
          work_package.reload
          service.call(description: "description v2", send_notifications: false)
          work_package.reload
          work_package.journals.reload.find_by(notes: "note to be deleted").delete

          service.call(description: "description v4", send_notifications: false)
        end

        it "creates a journal for the last change" do
          last_journal = work_package.last_journal

          expect(last_journal.data.description).to eql("description v4")
        end
      end

      it "has the timestamp of the work package update time for created_at" do
        expect(work_package.last_journal.created_at)
          .to eql(work_package.reload.updated_at)
      end

      it "has the updated_at of the work package as the lower bound for validity_period and no upper bound" do
        expect(work_package.last_journal.validity_period)
          .to eql(work_package.reload.updated_at...)
      end

      it "sets the upper bound of the preceeding journal to be the created_at time of the newly created journal" do
        former_last_journal = work_package.journals[-2]
        expect(former_last_journal.validity_period)
          .to eql(former_last_journal.created_at...work_package.last_journal.created_at)
      end
    end

    describe "attachments", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:attachment) { build(:attachment) }
      let(:attachment_id) { "attachments_#{attachment.id}" }

      before do
        work_package.attachments << attachment
        work_package.save!
      end

      context "for new attachment" do
        subject { work_package.last_journal.details }

        it { is_expected.to have_key attachment_id }

        it { expect(subject[attachment_id]).to eq([nil, attachment.filename]) }
      end

      context "when attachment saved w/o change" do
        it { expect { attachment.save! }.not_to change(Journal, :count) }
      end
    end

    describe "custom values", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:custom_field) { create(:work_package_custom_field) }
      let(:custom_value) do
        build(:custom_value,
              value: "false",
              custom_field:)
      end

      let(:custom_field_id) { "custom_fields_#{custom_value.custom_field_id}" }

      shared_context "for work package with custom value" do
        before do
          project.work_package_custom_fields << custom_field
          type.custom_fields << custom_field
          work_package.reload
          work_package.custom_values << custom_value
          work_package.save!
        end
      end

      context "for new custom value" do
        include_context "for work package with custom value"

        subject { work_package.last_journal.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([nil, custom_value.value]) }
      end

      context "for custom value modified" do
        include_context "for work package with custom value"

        let(:modified_custom_value) do
          create(:work_package_custom_value,
                 value: "true",
                 custom_field:)
        end

        before do
          work_package.custom_values = [modified_custom_value]
          work_package.save!
        end

        subject { work_package.last_journal.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([custom_value.value.to_s, modified_custom_value.value.to_s]) }
      end

      context "when work package saved w/o change" do
        include_context "for work package with custom value"

        let(:unmodified_custom_value) do
          create(:work_package_custom_value,
                 value: "false",
                 custom_field:)
        end

        before do
          work_package.custom_values = [unmodified_custom_value]
        end

        it { expect { work_package.save! }.not_to change(Journal, :count) }

        it "does not set an upper bound to the already existing journal" do
          work_package.save
          expect(work_package.last_journal.validity_period.end)
            .to be_nil
        end
      end

      context "when custom value removed" do
        include_context "for work package with custom value"

        before do
          work_package.custom_values.delete(custom_value)
          work_package.save!
        end

        subject { work_package.last_journal.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([custom_value.value, nil]) }
      end

      context "when custom value did not exist before" do
        let(:custom_field) do
          create(:work_package_custom_field,
                 is_required: false,
                 field_format: "list",
                 possible_values: ["", "1", "2", "3", "4", "5", "6", "7"])
        end
        let(:custom_value) do
          create(:custom_value,
                 value: "",
                 customized: work_package,
                 custom_field:)
        end

        describe "empty values are recognized as unchanged" do
          include_context "for work package with custom value"

          it { expect(work_package.last_journal.customizable_journals).to be_empty }
        end

        describe "empty values handled as non existing" do
          include_context "for work package with custom value"

          it { expect(work_package.last_journal.customizable_journals.count).to eq(0) }
        end
      end
    end

    describe "file_links", with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:file_link) { build(:file_link) }
      let(:file_link_id) { "file_links_#{file_link.id}" }

      before do
        work_package.file_links << file_link
        work_package.save!
      end

      context "for the new file link" do
        subject(:journal_details) { work_package.last_journal.details }

        it { is_expected.to have_key file_link_id }

        it {
          expect(journal_details[file_link_id])
            .to eq([nil, { "link_name" => file_link.origin_name, "storage_name" => nil }])
        }
      end

      context "when file link saved w/o change" do
        it {
          expect do
            file_link.save
            work_package.save_journals
          end.not_to change(Journal, :count)
        }
      end
    end

    context "for only journal notes adding" do
      subject do
        work_package.add_journal(user: User.current, notes: "some notes")
        work_package.save
        work_package
      end

      it "does not create a new journal entry" do
        expect { subject }.not_to change(work_package, :last_journal)
      end

      it "has the timestamp of the work package update time for updated_at" do
        expect(subject.last_journal.updated_at).to eql(work_package.reload.updated_at)
      end

      it "updates the updated_at time of the work package" do
        expect { subject.reload }.to change(work_package, :updated_at)
      end

      it "stores the note with the existing journal entry" do
        expect { subject }.to change { work_package.last_journal.notes }.from("").to("some notes")
      end
    end

    context "for mixed journal notes and attribute adding" do
      subject do
        work_package.add_journal(user: User.current, notes: "some notes")
        work_package.subject = "blubs"
        work_package.save
        work_package
      end

      it "does not create a new journal entry" do
        expect { subject }.not_to change(work_package, :last_journal)
      end

      it "has the timestamp of the work package update time for updated_at" do
        expect(subject.last_journal.updated_at).to eql(work_package.reload.updated_at)
      end

      it "updates the updated_at time of the work package" do
        expect { subject.reload }.to change(work_package, :updated_at)
      end

      it "stores the note with the existing journal entry" do
        expect { subject }.to change { work_package.last_journal.notes }.from("").to("some notes")
      end
    end

    context "for only journal cause adding" do
      subject do
        work_package.add_journal(
          user: User.current,
          cause: Journal::CausedByWorkPackagePredecessorChange.new(other_work_package)
        )
        work_package.save
        work_package
      end

      it "has the cause logged in the last journal" do
        expect(subject.last_journal.cause).to eql({
                                                    "type" => "work_package_predecessor_changed_times",
                                                    "work_package_id" => other_work_package.id
                                                  })
      end

      it "has the timestamp of the work package update time for created_at" do
        expect(subject.last_journal.updated_at).to eql(work_package.reload.updated_at)
      end

      it "updates the updated_at time of the work package" do
        expect { subject.reload }.to change(work_package, :updated_at)
      end

      it "does create a new journal entry" do
        expect { subject }.to change(work_package, :last_journal)
      end
    end

    context "for mixed journal cause, notes and attribute adding" do
      subject do
        work_package.add_journal(
          user: User.current,
          notes: "some notes",
          cause: Journal::CausedByWorkPackagePredecessorChange.new(other_work_package)
        )
        work_package.subject = "blubs"
        work_package.save
        work_package
      end

      it "has the timestamp of the work package update time for created_at" do
        expect(work_package.last_journal.updated_at).to eql(work_package.reload.updated_at)
      end

      it "does create a new journal entry" do
        expect { subject }.to change(work_package, :last_journal)
      end

      it "updates the updated_at time of the work package" do
        updated_at_before = work_package.updated_at

        expect(subject.reload.updated_at).not_to eql(updated_at_before)
      end

      it "stores the cause and note with the existing journal entry" do
        subject

        expect(work_package.last_journal.notes).to eq("some notes")
        expect(work_package.last_journal.cause_type).to eq("work_package_predecessor_changed_times")
        expect(work_package.last_journal.cause_work_package_id).to eq(other_work_package.id)
      end
    end

    context "when 2 updates with the same cause occur" do
      before do
        work_package.add_journal(
          user: User.current,
          cause: Journal::CausedByWorkPackagePredecessorChange.new(other_work_package)
        )
        work_package.subject = "new subject 1"
        work_package.save
      end

      subject do
        work_package.add_journal(
          user: User.current,
          cause: Journal::CausedByWorkPackagePredecessorChange.new(other_work_package)
        )
        work_package.subject = "new subject 2"
        work_package.save
      end

      it "does not create a new journal entry" do
        expect { subject }.not_to change(work_package, :last_journal)
      end

      it "stores the last update only" do
        subject

        expect(work_package.last_journal.new_value_for(:subject)).to eq("new subject 2")
        expect(work_package.last_journal.cause_type).to eq("work_package_predecessor_changed_times")
        expect(work_package.last_journal.cause_work_package_id).to eq(other_work_package.id)
      end
    end

    context "when updated within aggregation time" do
      subject(:journals) { work_package.journals }

      current_user { user1 }

      let(:notes) { nil }
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:new_status) { build(:status) }
      let(:changes) do
        {
          status: new_status,
          journal_notes: notes
        }.compact
      end

      before do
        login_as(new_author)

        work_package.attributes = changes
        work_package.save!
      end

      context "as author of last change" do
        let(:new_author) { user1 }

        it "leads to a single journal" do
          expect(subject.count).to be 1
        end

        it "is the initial journal" do
          expect(subject.first).to be_initial
        end

        it "contains the changes of both updates with the later overwriting the former" do
          expect(subject.first.data.status_id)
            .to eql changes[:status].id

          expect(subject.first.data.type_id)
            .to eql work_package.type_id
        end

        context "with a comment" do
          let(:notes) { "This is why I changed it." }

          it "leads to a single journal with the comment" do
            expect(subject.count).to be 1
            expect(subject.first.notes)
              .to eql notes
          end

          context "when adding a second comment" do
            let(:second_notes) { "Another comment, unrelated to the first one." }

            before do
              work_package.add_journal(user: new_author, notes: second_notes)
              work_package.save!
            end

            it "returns two journals" do
              expect(subject.count).to be 2
              expect(subject.first.notes).to eql notes
              expect(subject.second.notes).to eql second_notes
            end

            it "has one initial journal and one non-initial journal" do
              expect(subject.first).to be_initial
              expect(subject.second).not_to be_initial
            end
          end

          context "when adding another change without comment" do
            before do
              work_package.reload # need to update the lock_version, avoiding StaleObjectError
              work_package.subject = "foo"
              work_package.assigned_to = current_user
              work_package.save!
            end

            it "leads to a single journal with the comment of the replaced journal and the state both combined" do
              expect(subject.count).to eq 1

              expect(subject.first.notes)
                .to eql notes

              expect(subject.first.data.subject)
                .to eql "foo"

              expect(subject.first.data.assigned_to)
                .to eql current_user

              expect(subject.first.data.status_id)
                .to eql new_status.id
            end
          end

          context "when adding another change with a customized work package" do
            let(:custom_field) do
              create(:work_package_custom_field,
                     is_required: false,
                     field_format: "list",
                     possible_values: ["", "1", "2", "3", "4", "5", "6", "7"])
            end
            let(:custom_value) do
              create(:custom_value,
                     value: custom_field.custom_options.find { |co| co.value == "1" }.try(:id),
                     customized: work_package,
                     custom_field:)
            end

            before do
              custom_value
              work_package.reload # need to update the lock_version, avoiding StaleObjectError
              work_package.subject = "foo"
              work_package.save!
            end

            it "leads to a single journal with only one customizable journal" do
              expect(subject.count).to eq 1

              expect(subject.first.notes)
                .to eql notes

              expect(subject.first.data.subject)
                .to eql "foo"

              expect(subject.first.customizable_journals.count).to eq(1)
            end
          end
        end

        it "has the journal's creation time as the lower and no upper bound for validity_period" do
          expect(work_package.last_journal.validity_period)
            .to eql(work_package.last_journal.created_at...)
        end
      end

      context "with a different author" do
        let(:new_author) { user2 }

        it "leads to two journals" do
          expect(subject.count).to be 2
        end

        it "has the initial user as the author of the first journal" do
          expect(subject.first.user)
            .to eql current_user
        end

        it "has the second user as he author of the second journal" do
          expect(subject.second.user)
            .to eql new_author
        end

        it "has the changes (compared to the initial state) in the second journal" do
          expect(subject.second.get_changes)
            .to eql("status_id" => [status.id, new_status.id])
        end

        it "has the first journal's creation time as the lower and the second journal's creation time " \
           "as the upper bound for validity_period of the first journal" do
          expect(subject.first.validity_period)
            .to eql(subject.first.created_at...subject.second.created_at)
        end

        it "has the second journal's creation time as the lower and no upper bound for validity_period of the second journal" do
          expect(subject.second.validity_period)
            .to eql(subject.second.created_at...)
        end
      end
    end

    context "when updated after aggregation timeout expired", with_settings: { journal_aggregation_time_minutes: 1 } do
      let(:last_update_time) { 2.minutes.ago }

      subject(:journals) { work_package.journals }

      before do
        work_package.last_journal.update_columns(created_at: last_update_time,
                                                 updated_at: last_update_time,
                                                 validity_period: last_update_time..)
        work_package.update_columns(created_at: last_update_time,
                                    updated_at: last_update_time)

        work_package.status = build(:status)
        work_package.save!
      end

      it "creates a new journal" do
        expect(journals.count).to be 2
      end

      it "has the first journal's creation time as the lower and the second journal's creation time " \
         "as the upper bound for validity_period of the first journal" do
        expect(subject.first.validity_period)
          .to eql(subject.first.created_at...subject.second.created_at)
      end

      it "has the second journal's creation time as the lower and no upper bound for validity_period of the second journal" do
        expect(subject.second.validity_period)
          .to eql(subject.second.created_at...)
      end
    end

    context "when updating with aggregation disabled", with_settings: { journal_aggregation_time_minutes: 0 } do
      subject(:journals) { work_package.journals }

      context "when WP updated within milliseconds" do
        before do
          work_package.status = build(:status)
          work_package.save!
        end

        it "creates a new journal" do
          expect(journals.count).to be 2
        end
      end
    end

    context "when aggregation leads to an empty change (changing back and forth)",
            with_settings: { journal_aggregation_time_minutes: 1 } do
      let!(:work_package) do
        User.execute_as current_user do
          create(:work_package,
                 :created_in_past,
                 created_at: 5.minutes.ago,
                 project_id: project.id,
                 type:,
                 description: "Description",
                 priority:,
                 status:,
                 duration: 1)
        end
      end

      let(:other_status) { create(:status) }

      before do
        work_package.status = other_status
        work_package.save!
        work_package.status = status
        work_package.save!
      end

      it "creates a new journal" do
        expect(work_package.journals.count).to be 2
      end

      it "has the old state in the last journal`s data" do
        expect(work_package.journals.last.data.status_id).to be status.id
      end
    end
  end

  describe "#destroy" do
    let(:project) { create(:project) }
    let(:type) { create(:type) }
    let(:custom_field) do
      create(:integer_wp_custom_field) do |cf|
        project.work_package_custom_fields << cf
        type.custom_fields << cf
      end
    end
    let(:work_package) do
      create(:work_package,
             project:,
             type:,
             custom_field_values: { custom_field.id => 5 },
             attachments: [attachment],
             file_links: [file_link])
    end
    let(:attachment) { build(:attachment) }
    let(:file_link) { build(:file_link) }

    let!(:journal) { work_package.journals.first }
    let!(:customizable_journals) { journal.customizable_journals }
    let!(:attachable_journals) { journal.attachable_journals }
    let!(:storable_journals) { journal.storable_journals }

    before do
      work_package.destroy
    end

    it "removes the journal" do
      expect(Journal.find_by(id: journal.id))
        .to be_nil
    end

    it "removes the journal data" do
      expect(Journal::WorkPackageJournal.find_by(id: journal.data_id))
        .to be_nil
    end

    it "removes the customizable journals" do
      expect(Journal::CustomizableJournal.find_by(id: customizable_journals.map(&:id)))
        .to be_nil
    end

    it "removes the attachable journals" do
      expect(Journal::AttachableJournal.find_by(id: attachable_journals.map(&:id)))
        .to be_nil
    end

    it "removes the storable journals" do
      expect(Journal::StorableJournal.find_by(id: attachable_journals.map(&:id)))
        .to be_nil
    end
  end
end
