#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  describe '#copy' do
    let(:user) { FactoryGirl.create(:user) }
    let(:custom_field) { FactoryGirl.create(:work_package_custom_field) }
    let(:source_type) {
      FactoryGirl.create(:type,
                         custom_fields: [custom_field])
    }
    let(:source_project) {
      FactoryGirl.create(:project,
                         types: [source_type])
    }
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         project: source_project,
                         type: source_type,
                         author: user)
    }
    let(:custom_value) {
      FactoryGirl.create(:work_package_custom_value,
                         custom_field: custom_field,
                         customized: work_package,
                         value: false)
    }

    shared_examples_for 'copied work package' do
      subject { copy.id }

      it { is_expected.not_to eq(work_package.id) }
    end

    describe 'to the same project' do
      let(:copy) { work_package.move_to_project(source_project, nil, copy: true) }

      it_behaves_like 'copied work package'

      context 'project' do
        subject { copy.project }

        it { is_expected.to eq(source_project) }
      end
    end

    describe 'to a different project' do
      let(:target_type) { FactoryGirl.create(:type) }
      let(:target_project) {
        FactoryGirl.create(:project,
                           types: [target_type])
      }
      let(:copy) { work_package.move_to_project(target_project, target_type, copy: true) }

      it_behaves_like 'copied work package'

      context 'project' do
        subject { copy.project_id }

        it { is_expected.to eq(target_project.id) }
      end

      context 'type' do
        subject { copy.type_id }

        it { is_expected.to eq(target_type.id) }
      end

      context 'custom_fields' do
        before { custom_value }

        subject { copy.custom_value_for(custom_field.id) }

        it { is_expected.to be_nil }
      end

      describe '#attributes' do
        let(:copy) {
          work_package.move_to_project(target_project,
                                       target_type,
                                       copy: true,
                                       attributes: attributes)
        }

        context 'assigned_to' do
          let(:target_user) { FactoryGirl.create(:user) }
          let(:target_project_member) {
            FactoryGirl.create(:member,
                               project: target_project,
                               principal: target_user,
                               roles: [FactoryGirl.create(:role)])
          }
          let(:attributes) { { assigned_to_id: target_user.id } }

          before { target_project_member }

          it_behaves_like 'copied work package'

          subject { copy.assigned_to_id }

          it { is_expected.to eq(target_user.id) }
        end

        context 'status' do
          let(:target_status) { FactoryGirl.create(:status) }
          let(:attributes) { { status_id: target_status.id } }

          it_behaves_like 'copied work package'

          subject { copy.status_id }

          it { is_expected.to eq(target_status.id) }
        end

        context 'date' do
          let(:target_date) { Date.today + 14 }

          context 'start' do
            let(:attributes) { { start_date: target_date } }

            it_behaves_like 'copied work package'

            subject { copy.start_date }

            it { is_expected.to eq(target_date) }
          end

          context 'end' do
            let(:attributes) { { due_date: target_date } }

            it_behaves_like 'copied work package'

            subject { copy.due_date }

            it { is_expected.to eq(target_date) }
          end
        end
      end

      describe 'private project' do
        let(:role) {
          FactoryGirl.create(:role,
                             permissions: [:view_work_packages])
        }
        let(:target_project) {
          FactoryGirl.create(:project,
                             is_public: false,
                             types: [target_type])
        }
        let(:source_project_member) {
          FactoryGirl.create(:member,
                             project: source_project,
                             principal: user,
                             roles: [role])
        }

        before do
          source_project_member
          allow(User).to receive(:current).and_return user
        end

        it_behaves_like 'copied work package'

        context 'pre-condition' do
          subject { work_package.recipients }

          it { is_expected.to include(work_package.author.mail) }
        end

        subject { copy.recipients }

        it { is_expected.not_to include(copy.author.mail) }
      end

      describe 'with children' do
        let(:target_project) { FactoryGirl.create(:project, types: [source_type]) }
        let(:copy) { child.reload.move_to_project(target_project) }
        let!(:child) {
          FactoryGirl.create(:work_package, parent: work_package, project: source_project)
        }
        let!(:grandchild) {
          FactoryGirl.create(:work_package, parent: child, project: source_project)
        }

        context 'cross project relations deactivated' do
          before {
            allow(Setting).to receive(:cross_project_work_package_relations?).and_return(false)
          }

          it { expect(copy).to be_falsy }

          it { expect(child.reload.project).to eql(source_project) }

          describe 'grandchild' do
            before { copy }

            it { expect(grandchild.reload.project).to eql(source_project) }
          end
        end

        context 'cross project relations activated' do
          before {
            allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
          }

          it { expect(copy).to be_truthy }

          it { expect(copy.project).to eql(target_project) }

          describe 'grandchild' do
            before { copy }

            it { expect(grandchild.reload.project).to eql(target_project) }
          end
        end
      end
    end
  end

  shared_context 'project with required custom field' do
    before do
      project.work_package_custom_fields << custom_field
      type.custom_fields << custom_field

      source.save
    end
  end

  before do
    def self.change_custom_field_value(work_package, value)
      work_package.custom_field_values = { custom_field.id => value } unless value.nil?
      work_package.save
    end
  end

  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:custom_field) {
    FactoryGirl.create(:work_package_custom_field,
                       name: 'Database',
                       field_format: 'list',
                       possible_values: ['MySQL', 'PostgreSQL', 'Oracle'],
                       is_required: true)
  }

  describe '#copy_from' do
    include_context 'project with required custom field'

    let(:source) { FactoryGirl.build(:work_package) }
    let(:sink) { FactoryGirl.build(:work_package) }

    before do
      source.project_id = project.id
      change_custom_field_value(source, 'MySQL')
    end

    shared_examples_for 'work package copy' do
      context 'subject' do
        subject { sink.subject }

        it { is_expected.to eq(source.subject) }
      end

      context 'type' do
        subject { sink.type }

        it { is_expected.to eq(source.type) }
      end

      context 'status' do
        subject { sink.status }

        it { is_expected.to eq(source.status) }
      end

      context 'project' do
        subject { sink.project_id }

        it { is_expected.to eq(project_id) }
      end

      context 'watchers' do
        subject { sink.watchers.map(&:user_id) }

        it do
          is_expected.to match_array(source.watchers.map(&:user_id))
          sink.watchers.each { |w| expect(w).to be_valid }
        end
      end
    end

    shared_examples_for 'work package copy with custom field' do
      it_behaves_like 'work package copy'

      context 'custom_field' do
        subject { sink.custom_value_for(custom_field.id).value }

        it { is_expected.to eq('MySQL') }
      end
    end

    context 'with project' do
      let(:project_id) { source.project_id }

      describe 'should copy project' do

        before { sink.copy_from(source) }

        it_behaves_like 'work package copy with custom field'
      end

      describe 'should not copy excluded project' do
        let(:project_id) { sink.project_id }

        before { sink.copy_from(source, exclude: [:project_id]) }

        it_behaves_like 'work package copy'
      end

      describe 'should copy over watchers' do
        let(:project_id) { sink.project_id }
        let(:stub_user) { FactoryGirl.create(:user, member_in_project: project) }

        before do
          source.watchers.build(user: stub_user, watchable: source)

          sink.copy_from(source)
        end

        it_behaves_like 'work package copy'
      end
    end
  end
end
