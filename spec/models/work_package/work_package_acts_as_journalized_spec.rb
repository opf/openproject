#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  describe '#journal' do
    let(:type) { FactoryBot.create :type }
    let(:project) do
      FactoryBot.create :project,
                        types: [type]
    end
    let(:status) { FactoryBot.create :default_status }
    let(:priority) { FactoryBot.create :priority }
    let(:work_package) do
      FactoryBot.create(:work_package,
                        project_id: project.id,
                        type: type,
                        description: 'Description',
                        priority: priority)
    end
    let(:current_user) { FactoryBot.create(:user) }

    before do
      login_as(current_user)

      work_package
    end

    context 'on work package creation' do
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

      it 'notes the description to project' do
        expect(Journal.first.details[:description])
          .to match_array [nil, work_package.description]
      end

      it 'has the timestamp of the work package update time for created_at' do
        # This seemingly unnecessary reload leads to the updated_at having the same
        # precision as the created_at of the Journal. It is database dependent, so it would work without
        # reload on PG 12 but does not work on PG 9.
        expect(Journal.first.created_at)
          .to eql(work_package.reload.updated_at)
      end
    end

    context 'nothing is changed' do
      before do
        work_package.save!
      end

      it { expect(Journal.all.count).to eq(1) }
    end

    context 'different newlines' do
      let(:description) { "Description\n\nwith newlines\n\nembedded" }
      let(:changed_description) { description.gsub("\n", "\r\n") }
      let!(:work_package_1) do
        FactoryBot.create(:work_package,
                          project_id: project.id,
                          type: type,
                          description: description,
                          priority: priority)
      end

      before do
        work_package_1.description = changed_description
      end

      context 'when a new journal is created tracking a simultaneously applied change' do
        before do
          work_package_1.subject += 'changed'
          work_package_1.save!
        end

        describe 'does not track the changed newline characters' do
          subject { work_package_1.journals.last.data.description }

          it { is_expected.to eq(description) }
        end

        describe 'tracks only the other change' do
          subject { work_package_1.journals.last.details }

          it { is_expected.to have_key :subject }
          it { is_expected.not_to have_key :description }
        end
      end

      context 'when there is a legacy journal containing non-escaped newlines' do
        let!(:work_package_journal_1) do
          FactoryBot.create(:work_package_journal,
                            journable_id: work_package_1.id,
                            version: 2,
                            data: FactoryBot.build(:journal_work_package_journal,
                                                   description: description))
        end
        let!(:work_package_journal_2) do
          FactoryBot.create(:work_package_journal,
                            journable_id: work_package_1.id,
                            version: 3,
                            data: FactoryBot.build(:journal_work_package_journal,
                                                   description: changed_description))
        end

        subject { work_package_1.journals.reload.last.details }

        it { is_expected.not_to have_key :description }
      end
    end

    context 'on work package change' do
      let(:parent_work_package) do
        FactoryBot.create(:work_package,
                          project_id: project.id,
                          type: type,
                          priority: priority)
      end
      let(:type_2) { FactoryBot.create :type }
      let(:status_2) { FactoryBot.create :status }
      let(:priority_2) { FactoryBot.create :priority }

      before do
        project.types << type_2

        work_package.subject = 'changed'
        work_package.description = 'changed'
        work_package.type = type_2
        work_package.status = status_2
        work_package.priority = priority_2
        work_package.start_date = Date.new(2013, 1, 24)
        work_package.due_date = Date.new(2013, 1, 31)
        work_package.estimated_hours = 40.0
        work_package.assigned_to = User.current
        work_package.responsible = User.current
        work_package.parent = parent_work_package

        work_package.save!
      end

      context 'last created journal' do
        subject { work_package.journals.reload.last.details }

        it 'contains all changes' do
          %i(subject description type_id status_id priority_id
             start_date due_date estimated_hours assigned_to_id
             responsible_id parent_id).each do |a|
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
        context 'description' do
          let(:property) { 'description' }

          context 'old_value' do
            let(:expected_value) { 'Description' }

            it_behaves_like 'old value'
          end

          context 'new value' do
            let(:expected_value) { 'changed' }

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

        it 'should create a journal for the last change' do
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

    context 'attachments' do
      let(:attachment) { FactoryBot.build :attachment }
      let(:attachment_id) { "attachments_#{attachment.id}" }

      before do
        work_package.attachments << attachment
        work_package.save!
      end

      context 'new attachment' do
        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key attachment_id }

        it { expect(subject[attachment_id]).to eq([nil, attachment.filename]) }
      end

      context 'attachment saved w/o change' do
        before do
          @original_journal_count = work_package.journals.reload.count

          attachment.save!
        end

        subject { work_package.journals.reload.count }

        it { is_expected.to eq(@original_journal_count) }
      end

      context 'attachment removed' do
        before do
          work_package.attachments.delete(attachment)
        end

        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key attachment_id }

        it { expect(subject[attachment_id]).to eq([attachment.filename, nil]) }
      end
    end

    context 'custom values' do
      let(:custom_field) { FactoryBot.create :work_package_custom_field }
      let(:custom_value) do
        FactoryBot.build :custom_value,
                         value: 'false',
                         custom_field: custom_field
      end

      let(:custom_field_id) { "custom_fields_#{custom_value.custom_field_id}" }

      shared_context 'work package with custom value' do
        before do
          project.work_package_custom_fields << custom_field
          type.custom_fields << custom_field
          work_package.reload
          work_package.custom_values << custom_value
          work_package.save!
        end
      end

      context 'new custom value' do
        include_context 'work package with custom value'

        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([nil, custom_value.value]) }
      end

      context 'custom value modified' do
        include_context 'work package with custom value'

        let(:modified_custom_value) do
          FactoryBot.create :custom_value,
                            value: 'true',
                            custom_field: custom_field
        end
        before do
          work_package.custom_values = [modified_custom_value]
          work_package.save!
        end

        subject { work_package.journals.reload.last.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([custom_value.value.to_s, modified_custom_value.value.to_s]) }
      end

      context 'work package saved w/o change' do
        include_context 'work package with custom value'

        let(:unmodified_custom_value) do
          FactoryBot.create :custom_value,
                            value: 'false',
                            custom_field: custom_field
        end
        before do
          @original_journal_count = work_package.journals.reload.count

          work_package.custom_values = [unmodified_custom_value]

          work_package.save!
        end

        subject { work_package.journals.reload.count }

        it { is_expected.to eq(@original_journal_count) }
      end

      context 'custom value removed' do
        include_context 'work package with custom value'

        before do
          work_package.custom_values.delete(custom_value)
          work_package.save!
        end

        subject { work_package.journals.last.details }

        it { is_expected.to have_key custom_field_id }

        it { expect(subject[custom_field_id]).to eq([custom_value.value, nil]) }
      end

      context 'custom value did not exist before' do
        let(:custom_field) do
          FactoryBot.create :work_package_custom_field,
                            is_required: false,
                            field_format: 'list',
                            possible_values: ['', '1', '2', '3', '4', '5', '6', '7']
        end
        let(:custom_value) do
          FactoryBot.create :custom_value,
                            value: '',
                            customized: work_package,
                            custom_field: custom_field
        end

        describe 'empty values are recognized as unchanged' do
          include_context 'work package with custom value'

          it { expect(work_package.journals.reload.last.customizable_journals).to be_empty }
        end

        describe 'empty values handled as non existing' do
          include_context 'work package with custom value'

          it { expect(work_package.journals.reload.last.customizable_journals.count).to eq(0) }
        end
      end
    end

    context 'on only journal notes adding' do
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

    context 'on mixed journal notes and attribute adding' do
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
  end

  describe 'Acts as journalized' do
    before(:each) do
      @type ||= FactoryBot.create(:type_feature)

      @status_resolved ||= FactoryBot.create(:status, name: 'Resolved')
      @status_open ||= FactoryBot.create(:status, name: 'Open')
      @status_rejected ||= FactoryBot.create(:status, name: 'Rejected')

      role = FactoryBot.create(:role)
      FactoryBot.create(:workflow,
                        old_status: @status_open,
                        new_status: @status_resolved,
                        role: role,
                        type_id: @type.id)
      FactoryBot.create(:workflow,
                        old_status: @status_resolved,
                        new_status: @status_rejected,
                        role: role,
                        type_id: @type.id)

      @priority_low ||= FactoryBot.create(:priority_low)
      @priority_high ||= FactoryBot.create(:priority_high)
      @project ||= FactoryBot.create(:project, no_types: true, types: [@type])

      @current = FactoryBot.create(:user, login: 'user1', mail: 'user1@users.com')
      allow(User).to receive(:current).and_return(@current)
      @project.add_member!(@current, role)

      @user2 = FactoryBot.create(:user, login: 'user2', mail: 'user2@users.com')

      @issue ||= FactoryBot.create(:work_package,
                                   project: @project,
                                   status: @status_open,
                                   type: @type,
                                   author: @current)
    end

    describe 'ignore blank to blank transitions' do
      it 'should not include the "nil to empty string"-transition' do
        @issue.description = nil
        @issue.save!

        @issue.description = ''
        @issue.save!
      end
    end
  end
end
