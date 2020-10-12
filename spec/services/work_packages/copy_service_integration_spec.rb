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

describe WorkPackages::CopyService, 'integration', type: :model do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: permissions)
  end

  let(:permissions) do
    %i(view_work_packages add_work_packages manage_subtasks)
  end

  let(:type) do
    FactoryBot.create(:type_standard,
                      custom_fields: [custom_field])
  end
  let(:project) { FactoryBot.create(:project, types: [type]) }
  let(:work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: type)
  end
  let(:instance) { described_class.new(work_package: work_package, user: user) }
  let(:custom_field) { FactoryBot.create(:work_package_custom_field) }
  let(:custom_value) do
    FactoryBot.create(:work_package_custom_value,
                      custom_field: custom_field,
                      customized: work_package,
                      value: false)
  end
  let(:source_project) { project }
  let(:source_type) { type }
  let(:attributes) { {} }
  let(:copy) do
    service_result
      .result
  end
  let(:service_result) do
    instance
      .call(attributes)
  end

  before do
    login_as(user)
  end

  describe '#call' do
    shared_examples_for 'copied work package' do
      subject { copy.id }

      it { is_expected.not_to eq(work_package.id) }
    end

    describe 'to the same project' do
      it_behaves_like 'copied work package'

      context 'project' do
        subject { copy.project }

        it { is_expected.to eq(source_project) }
      end
    end

    describe 'to a different project' do
      let(:target_type) { FactoryBot.create(:type, custom_fields: target_custom_fields) }
      let(:target_project) do
        p = FactoryBot.create(:project,
                              types: [target_type],
                              work_package_custom_fields: target_custom_fields)

        FactoryBot.create(:member,
                          project: p,
                          roles: [target_role],
                          user: user)

        p
      end
      let(:target_custom_fields) { [] }
      let(:target_role) { FactoryBot.create(:role, permissions: target_permissions) }
      let(:target_permissions) { %i(add_work_packages manage_subtasks) }
      let(:attributes) { { project: target_project, type: target_type } }

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
        let(:custom_field) do
          FactoryBot.create(
            :work_package_custom_field,
            field_format:    'text',
            is_required:     true,
            is_for_all:      false
          )
        end
        let(:target_custom_fields) { [custom_field] }

        it 'does not copy the work package' do
          expect(service_result).to be_failure
        end
      end

      describe '#attributes' do
        context 'assigned_to' do
          let(:target_user) { FactoryBot.create(:user) }
          let(:target_project_member) do
            FactoryBot.create(:member,
                              project: target_project,
                              principal: target_user,
                              roles: [FactoryBot.create(:role)])
          end
          let(:attributes) { { assigned_to_id: target_user.id } }

          before do
            target_project_member
          end

          it_behaves_like 'copied work package'

          subject { copy.assigned_to_id }

          it { is_expected.to eq(target_user.id) }
        end

        context 'status' do
          let(:target_status) { FactoryBot.create(:status) }
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

      describe 'with children' do
        let(:instance) { described_class.new(work_package: child, user: user) }
        let!(:child) do
          FactoryBot.create(:work_package, parent: work_package, project: source_project)
        end
        let(:grandchild) do
          FactoryBot.create(:work_package, parent: child, project: source_project)
        end

        context 'cross project relations deactivated' do
          before do
            allow(Setting)
              .to receive(:cross_project_work_package_relations?)
              .and_return(false)
          end

          it do
            expect(service_result).to be_failure
          end

          it do
            expect(child.reload.project).to eql(source_project)
          end

          describe 'grandchild' do
            before do
              grandchild
            end

            it { expect(grandchild.reload.project).to eql(source_project) }
          end
        end

        context 'cross project relations activated' do
          before do
            allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
          end

          it 'is success' do
            expect(service_result)
              .to be_success
          end

          it 'has the original parent as its parent' do
            expect(copy.parent).to eql(child.parent)
          end

          it do
            expect(copy.project).to eql(target_project)
          end

          describe 'grandchild' do
            before do
              grandchild
            end

            it { expect(grandchild.reload.project).to eql(source_project) }
            it { expect(copy.descendants).to be_empty }
          end
        end
      end
    end
  end
end
