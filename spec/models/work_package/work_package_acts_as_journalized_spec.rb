#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'

describe WorkPackage, type: :model do
  describe '#journal' do
    let(:type) { create :type }
    let(:project) do
      create :project,
             types: [type]
    end
    let(:status) { create :default_status }
    let(:priority) { create :priority }
    let(:work_package) do
      create(:work_package,
             project_id: project.id,
             type:,
             description: 'Description',
             priority:,
             status:,
             duration: 1)
    end
    let(:current_user) { create(:user) }

    before do
      login_as(current_user)

      work_package
    end

    context 'for work package creation' do
      it { expect(Journal.all.count).to eq(1) }

      it 'has a journal entry' do
        expect(Journal.first.journable).to eq(work_package)
      end

      it 'notes the changes to subject' do
        expect(Journal.first.details[:subject])
          .to match_array [nil, work_package.subject]
      end

      it 'notes the changes to project' do
        expect(Journal.first.details[:project_id])
          .to match_array [nil, work_package.project_id]
      end

      it 'notes the description' do
        expect(Journal.first.details[:description])
          .to match_array [nil, work_package.description]
      end

      it 'notes the scheduling mode' do
        expect(Journal.first.details[:schedule_manually])
          .to match_array [nil, false]
      end

      it 'has the timestamp of the work package update time for created_at' do
        # This seemingly unnecessary reload leads to the updated_at having the same
        # precision as the created_at of the Journal. It is database dependent, so it would work without
        # reload on PG 12 but does not work on PG 9.
        expect(Journal.first.created_at)
          .to eql(work_package.reload.updated_at)
      end
    end

    context 'when nothing is changed' do
      it { expect { work_package.save! }.not_to change(Journal, :count) }
    end

    context 'for different newlines', with_settings: { journal_aggregation_time_minutes: 0 } do
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

      context 'when a new journal is created tracking a simultaneously applied change' do
        before do
          work_package1.subject += 'changed'
          work_package1.save!
        end

        describe 'does not track the changed newline characters' do
          subject { work_package1.journals.last.data.description }

          it { is_expected.to eq(description) }
        end

        describe 'tracks only the other change' do
          subject { work_package1.journals.last.details }

          it { is_expected.to have_key :subject }
          it { is_expected.not_to have_key :description }
        end
      end

      context 'when there is a legacy journal containing non-escaped newlines' do
        let!(:work_package_journal1) do
          create(:work_package_journal,
                 journable_id: work_package1.id,
                 version: 2,
                 data: build(:journal_work_package_journal,
                             description:))
        end
        let!(:work_package_journal2) do
          create(:work_package_journal,
                 journable_id: work_package1.id,
                 version: 3,
                 data: build(:journal_work_package_journal,
                             description: changed_description))
        end

        subject { work_package1.journals.reload.last.details }

        it { is_expected.not_to have_key :description }
      end
    end

    describe 'on work package change', with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:parent_work_package) do
        create(:work_package,
               project_id: project.id,
               type:,
               priority:)
      end
      let(:type2) { create :type }
      let(:status2) { create :status }
      let(:priority2) { create :priority }

      before do
        project.types << type2

        work_package.subject = 'changed'
        work_package.description = 'changed'
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

      context 'for last created journal' do
        subject { work_package.journals.reload.last.details }

        it 'contains all changes' do
          %i(subject description type_id status_id priority_id
             start_date due_date estimated_hours assigned_to_id
             responsible_id parent_id schedule_manually).each do |a|
            expect(subject).to have_key(a.to_s), "Missing change for #{a}"
          end
        end
      end

      shared_examples_for 'old value' do
        subject { work_package.last_journal.old_value_for(property) }

        it { is_expected.to eq(expected_value) }
      end

      shared_examples_for 'new value' do
        subject { work_package.last_journal.new_value_for(property) }

        it { is_expected.to eq(expected_value) }
      end

      describe 'journaled value for' do
        describe 'description' do
          let(:property) { 'description' }

          context 'for old value' do
            let(:expected_value) { 'Description' }

            it_behaves_like 'old value'
          end

          context 'for new value' do
            let(:expected_value) { 'changed' }

            it_behaves_like 'new value'
          end
        end

        describe 'schedule_manually' do
          let(:property) { 'schedule_manually' }

          context 'for old value' do
            let(:expected_value) { false }

            it_behaves_like 'old value'
          end

          context 'for new value' do
            let(:expected_value) { true }

            it_behaves_like 'new value'
          end
        end

        describe 'duration' do
          let(:property) { 'duration' }

          context 'for old value' do
            let(:expected_value) { 1 }

            it_behaves_like 'old value'
          end

          context 'for new value' do
            let(:expected_value) { 8 }

            it_behaves_like 'new value'
          end
        end
      end

      describe 'adding journal with a missing journal and an existing journal' do
        before do
          allow(WorkPackages::UpdateContract).to receive(:new).and_return(NoopContract.new)
          service = WorkPackages::UpdateService.new(user: current_user, model: work_package)
          service.call(journal_notes: 'note to be deleted', send_notifications: false)
          work_package.reload
          service.call(description: 'description v2', send_notifications: false)
          work_package.reload
          work_package.journals.reload.find_by(notes: 'note to be deleted').delete

          service.call(description: 'description v4', send_notifications: false)
        end

        it 'creates a journal for the last change' do
          last_journal = work_package.journals.order(:id).last

          expect(last_journal.data.description).to eql('description v4')
        end
      end

      it 'has the timestamp of the work package update time for created_at' do
        # This seemingly unnecessary reload leads to the updated_at having the same
        # precision as the created_at of the Journal. It is database dependent, so it would work without
        # reload on PG 12 but does not work on PG 9.
        expect(work_package.journals.order(:id).last.created_at)
          .to eql(work_package.reload.updated_at)
      end
    end

    describe 'attachments', with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:attachment) { build :attachment }
      let(:attachment_id) { "attachments_#{attachment.id}" }

      before do
        work_package.attachments << attachment
        work_package.save!
      end

      context 'for new attachment' do
        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key attachment_id }

        it { expect(subject[attachment_id]).to eq([nil, attachment.filename]) }
      end

      context 'when attachment saved w/o change' do
        it { expect { attachment.save! }.not_to change(Journal, :count) }
      end
    end

    describe 'custom values', with_settings: { journal_aggregation_time_minutes: 0 } do
      let(:custom_field) { create :work_package_custom_field }
      let(:custom_value) do
        build :custom_value,
              value: 'false',
              custom_field:
      end

      let(:custom_field_id) { "custom_fields_#{custom_value.custom_field_id}" }

      shared_context 'for work package with custom value' do
        before do
          project.work_package_custom_fields << custom_field
          type.custom_fields << custom_field
          work_package.reload
          work_package.custom_values << custom_value
          work_package.save!
        end
      end

      context 'for new custom value' do
        include_context 'for work package with custom value'

        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([nil, custom_value.value]) }
      end

      context 'for custom value modified' do
        include_context 'for work package with custom value'

        let(:modified_custom_value) do
          create :custom_value,
                 value: 'true',
                 custom_field:
        end

        before do
          work_package.custom_values = [modified_custom_value]
          work_package.save!
        end

        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([custom_value.value.to_s, modified_custom_value.value.to_s]) }
      end

      context 'when work package saved w/o change' do
        include_context 'for work package with custom value'

        let(:unmodified_custom_value) do
          create :custom_value,
                 value: 'false',
                 custom_field:
        end

        before do
          work_package.custom_values = [unmodified_custom_value]
        end

        it { expect { work_package.save! }.not_to change(Journal, :count) }
      end

      context 'when custom value removed' do
        include_context 'for work package with custom value'

        before do
          work_package.custom_values.delete(custom_value)
          work_package.save!
        end

        subject { work_package.journals.last.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([custom_value.value, nil]) }
      end

      context 'when custom value did not exist before' do
        let(:custom_field) do
          create :work_package_custom_field,
                 is_required: false,
                 field_format: 'list',
                 possible_values: ['', '1', '2', '3', '4', '5', '6', '7']
        end
        let(:custom_value) do
          create :custom_value,
                 value: '',
                 customized: work_package,
                 custom_field:
        end

        describe 'empty values are recognized as unchanged' do
          include_context 'for work package with custom value'

          it { expect(work_package.journals.reload.last.customizable_journals).to be_empty }
        end

        describe 'empty values handled as non existing' do
          include_context 'for work package with custom value'

          it { expect(work_package.journals.reload.last.customizable_journals.count).to eq(0) }
        end
      end
    end

    context 'for only journal notes adding' do
      before do
        work_package.add_journal(User.current, 'some notes')
        work_package.save
      end

      it 'has the timestamp of the work package update time for created_at' do
        # This seemingly unnecessary reload leads to the updated_at having the same
        # precision as the created_at of the Journal. It is database dependent, so it would work without
        # reload on PG 12 but does not work on PG 9.
        expect(work_package.journals.last.created_at)
          .to eql(work_package.reload.updated_at)
      end
    end

    context 'for mixed journal notes and attribute adding' do
      before do
        work_package.add_journal(User.current, 'some notes')
        work_package.subject = 'blubs'
        work_package.save
      end

      it 'has the timestamp of the work package update time for created_at' do
        # This seemingly unnecessary reload leads to the updated_at having the same
        # precision as the created_at of the Journal. It is database dependent, so it would work without
        # reload on PG 12 but does not work on PG 9.
        expect(work_package.journals.last.created_at)
          .to eql(work_package.reload.updated_at)
      end
    end

    context 'when updated within aggregation time' do
      subject(:journals) { work_package.journals }

      let(:current_user) { user1 }

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

      context 'as author of last change' do
        let(:new_author) { user1 }

        it 'leads to a single journal' do
          expect(subject.count).to be 1
        end

        it 'is the initial journal' do
          expect(subject.first).to be_initial
        end

        it 'contains the changes of both updates with the later overwriting the former' do
          expect(subject.first.data.status_id)
            .to eql changes[:status].id

          expect(subject.first.data.type_id)
            .to eql work_package.type_id
        end

        context 'with a comment' do
          let(:notes) { 'This is why I changed it.' }

          it 'leads to a single journal with the comment' do
            expect(subject.count).to be 1
            expect(subject.first.notes)
              .to eql notes
          end

          context 'when adding a second comment' do
            let(:second_notes) { 'Another comment, unrelated to the first one.' }

            before do
              work_package.add_journal(new_author, second_notes)
              work_package.save!
            end

            it 'returns two journals' do
              expect(subject.count).to be 2
              expect(subject.first.notes).to eql notes
              expect(subject.second.notes).to eql second_notes
            end

            it 'has one initial journal and one non-initial journal' do
              expect(subject.first).to be_initial
              expect(subject.second).not_to be_initial
            end
          end

          context 'when adding another change without comment' do
            before do
              work_package.reload # need to update the lock_version, avoiding StaleObjectError
              changes = { subject: 'foo' }

              work_package.attributes = changes
              work_package.save!
            end

            it 'leads to a single journal with the comment of the replaced journal and the state of the second' do
              expect(subject.count).to be 1

              expect(subject.first.notes)
                .to eql notes

              expect(subject.first.data.subject)
                .to eql 'foo'
            end
          end
        end
      end

      context 'as a different author' do
        let(:new_author) { user2 }

        it 'leads to two journals' do
          expect(subject.count).to be 2
          expect(subject.first.user)
            .to eql current_user

          expect(subject.second.user)
            .to eql new_author

          expect(subject.second.get_changes)
            .to eql("status_id" => [status.id, new_status.id])
        end
      end
    end

    context 'when updated after aggregation timeout expired', with_settings: { journal_aggregation_time_minutes: 1 } do
      subject(:journals) { work_package.journals }

      before do
        work_package.journals.last.update_columns(created_at: 2.minutes.ago,
                                                  updated_at: 2.minutes.ago)

        work_package.status = build(:status)
        work_package.save!
      end

      it 'creates a new journal' do
        expect(journals.count).to be 2
      end
    end

    context 'when updating with aggregation disabled', with_settings: { journal_aggregation_time_minutes: 0 } do
      subject(:journals) { work_package.journals }

      context 'when WP updated within milliseconds' do
        before do
          work_package.status = build(:status)
          work_package.save!
        end

        it 'creates a new journal' do
          expect(journals.count).to be 2
        end
      end
    end
  end

  describe 'on #destroy' do
    let(:project) { create(:project) }
    let(:type) { create(:type) }
    let(:custom_field) do
      create(:int_wp_custom_field).tap do |cf|
        project.work_package_custom_fields << cf
        type.custom_fields << cf
      end
    end
    let(:work_package) do
      create(:work_package,
             project:,
             type:,
             custom_field_values: { custom_field.id => 5 },
             attachments: [attachment])
    end
    let(:attachment) { build(:attachment) }
    let!(:journal) { work_package.journals.first }
    let!(:customizable_journals) { journal.customizable_journals }
    let!(:attachable_journals) { journal.attachable_journals }

    before do
      work_package.destroy
    end

    it 'removes the journal' do
      expect(Journal.find_by(id: journal.id))
        .to be_nil
    end

    it 'removes the journal data' do
      expect(Journal::WorkPackageJournal.find_by(id: journal.data_id))
        .to be_nil
    end

    it 'removes the customizable journals' do
      expect(Journal::CustomizableJournal.find_by(id: customizable_journals.map(&:id)))
        .to be_nil
    end

    it 'removes the attachable journals' do
      expect(Journal::AttachableJournal.find_by(id: attachable_journals.map(&:id)))
        .to be_nil
    end
  end
end
