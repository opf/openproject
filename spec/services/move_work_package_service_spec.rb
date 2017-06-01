#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe MoveWorkPackageService, type: :model do
  let(:user) { FactoryGirl.create(:user) }
  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       type: type)
  }
  let(:instance) { MoveWorkPackageService.new(work_package, user) }

  before do
    login_as(user)
  end

  def mock_allowed_to_move_to_project(project, is_allowed = true)
    allowed_scope = double('allowed_scope', :'exists?' => is_allowed)

    allow(WorkPackage)
      .to receive(:allowed_target_projects_on_move)
      .with(user)
      .and_return(allowed_scope)

    allow(allowed_scope)
      .to receive(:where)
      .with(id: project.id)
      .and_return(allowed_scope)
  end

  describe '#call' do
    context 'when moving' do
      let(:target_project) { FactoryGirl.create(:project) }

      before do
        work_package

        mock_allowed_to_move_to_project(target_project, true)
      end

      shared_examples_for 'moved work package' do
        subject { work_package.project }

        it { is_expected.to eq(target_project) }
      end

      context 'the project the work package is moved to' do
        it_behaves_like 'moved work package' do
          before do
            instance.call(target_project)
          end
        end

        it 'will not move if the user does not have the permission' do
          mock_allowed_to_move_to_project(target_project, false)

          instance.call(target_project)

          expect(work_package.project).to eql(project)
        end
      end

      describe '#time_entries' do
        let(:time_entry_1) {
          FactoryGirl.create(:time_entry,
                             project: project,
                             work_package: work_package)
        }
        let(:time_entry_2) {
          FactoryGirl.create(:time_entry,
                             project: project,
                             work_package: work_package)
        }

        before do
          time_entry_1
          time_entry_2

          work_package.reload
          instance.call(target_project)

          time_entry_1.reload
          time_entry_2.reload
        end

        context 'time entry 1' do
          subject { work_package.time_entries }

          it { is_expected.to include(time_entry_1) }
        end

        context 'time entry 2' do
          subject { work_package.time_entries }

          it { is_expected.to include(time_entry_2) }
        end

        it_behaves_like 'moved work package'
      end

      describe '#category' do
        let(:category) {
          FactoryGirl.create(:category,
                             project: project)
        }

        before do
          work_package.category = category
          work_package.save!

          work_package.reload
        end

        context 'with same category' do
          let(:target_category) {
            FactoryGirl.create(:category,
                               name: category.name,
                               project: target_project)
          }

          before do
            target_category

            instance.call(target_project)
          end

          describe 'category moved' do
            subject { work_package.category_id }

            it { is_expected.to eq(target_category.id) }
          end

          it_behaves_like 'moved work package'
        end

        context 'w/o target category' do
          before do
            instance.call(target_project)
          end

          describe 'category discarded' do
            subject { work_package.category_id }

            it { is_expected.to be_nil }
          end

          it_behaves_like 'moved work package'
        end
      end

      describe '#version' do
        let(:sharing) { 'none' }
        let(:version) {
          FactoryGirl.create(:version,
                             status: 'open',
                             project: project,
                             sharing: sharing)
        }
        let(:work_package) {
          FactoryGirl.create(:work_package,
                             fixed_version: version,
                             project: project)
        }

        before do
          instance.call(target_project)
        end

        it_behaves_like 'moved work package'

        context 'unshared version' do
          subject { work_package.fixed_version }

          it { is_expected.to be_nil }
        end

        context 'system wide shared version' do
          let(:sharing) { 'system' }

          subject { work_package.fixed_version }

          it { is_expected.to eq(version) }
        end

        context 'move work package in project hierarchy' do
          let(:target_project) {
            FactoryGirl.create(:project,
                               parent: project)
          }

          context 'unshared version' do
            subject { work_package.fixed_version }

            it { is_expected.to be_nil }
          end

          context 'shared version' do
            let(:sharing) { 'tree' }

            subject { work_package.fixed_version }

            it { is_expected.to eq(version) }
          end
        end
      end

      describe '#type' do
        let(:target_type) { FactoryGirl.create(:type) }
        let(:target_project) {
          FactoryGirl.create(:project,
                             types: [target_type])
        }

        it 'is false if the current type is not defined for the new project' do
          expect(instance.call(target_project)).to be_falsey
        end
      end
    end

    describe 'when copying' do
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
        let(:copy) {
          mock_allowed_to_move_to_project(source_project)
          instance.call(source_project, nil, copy: true)
        }

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
        let(:copy) do
          mock_allowed_to_move_to_project(target_project)
          instance.call(target_project, target_type, copy: true)
        end

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
          before do
            custom_value
          end

          subject { copy.custom_value_for(custom_field.id) }

          it { is_expected.to be_nil }
        end

        context 'required custom field in the target project' do
          let(:custom_field) {
            FactoryGirl.create(
              :work_package_custom_field,
              field_format:    'text',
              is_required:     true,
              is_for_all:      false
            )
          }
          let!(:target_type) { FactoryGirl.create(:type, custom_fields: [custom_field]) }
          let!(:target_project) {
            FactoryGirl.create(
              :project,
              types: [target_type],
              work_package_custom_fields: [custom_field]
            )
          }
          it 'does not copy the work package' do
            mock_allowed_to_move_to_project(target_project)
            result = instance.call(target_project, target_type, copy: true)
            expect(result).to be_falsey
          end
        end

        describe '#attributes' do
          let(:copy) {
            mock_allowed_to_move_to_project(target_project)
            instance.call(target_project,
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

            before do
              target_project_member
            end

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

            it { is_expected.to include(work_package.author) }
          end

          subject { copy.recipients }

          it { is_expected.not_to include(copy.author) }
        end

        describe 'with children' do
          let(:target_project) { FactoryGirl.create(:project, types: [source_type]) }
          let(:instance) { MoveWorkPackageService.new(child, user) }
          let(:copy) do
            mock_allowed_to_move_to_project(target_project)

            child.reload

            instance.call(target_project)
          end
          let!(:child) {
            FactoryGirl.create(:work_package, parent: work_package, project: source_project)
          }
          let!(:grandchild) {
            FactoryGirl.create(:work_package, parent: child, project: source_project)
          }

          context 'cross project relations deactivated' do
            before do
              allow(Setting).to receive(:cross_project_work_package_relations?).and_return(false)
            end

            it do
              expect(copy).to be_falsy
            end

            it do
              expect(child.reload.project).to eql(source_project)
            end

            describe 'grandchild' do
              before do
                copy
              end

              it { expect(grandchild.reload.project).to eql(source_project) }
            end
          end

          context 'cross project relations activated' do
            before do
              allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
            end

            it do
              expect(copy).to be_truthy
            end

            it do
              expect(copy.project).to eql(target_project)
            end

            describe 'grandchild' do
              before do
                copy
              end

              it { expect(grandchild.reload.project).to eql(target_project) }
            end
          end
        end
      end
    end
  end
end
