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

describe WorkPackage, 'status', type: :model do
  let(:status) { FactoryGirl.create(:status) }
  let!(:work_package) {
    FactoryGirl.create(:work_package,
                       status: status)
  }

  it 'can read planning_elements w/ the help of the has_many association' do
    expect(WorkPackage.where(status_id: status.id).count).to eq(1)
    expect(WorkPackage.where(status_id: status.id).first).to eq(work_package)
  end

  describe 'transition' do
    let(:user) { FactoryGirl.create(:user) }
    let(:type) { FactoryGirl.create(:type) }
    let(:project) {
      FactoryGirl.create(:project,
                         types: [type])
    }
    let(:role) {
      FactoryGirl.create(:role,
                         permissions: [:edit_work_packages])
    }
    let(:invalid_role) {
      FactoryGirl.create(:role,
                         permissions: [:edit_work_packages])
    }
    let!(:member) {
      FactoryGirl.create(:member,
                         project: project,
                         principal: user,
                         roles: [role])
    }
    let(:status_2) { FactoryGirl.create(:status) }
    let!(:work_package) {
      FactoryGirl.create(:work_package,
                         project_id: project.id,
                         type_id: type.id,
                         status_id: status.id)
    }
    let(:valid_user_workflow) {
      FactoryGirl.create(:workflow,
                         type_id: type.id,
                         old_status: status,
                         new_status: status_2,
                         role: role)
    }
    let(:invalid_user_workflow) {
      FactoryGirl.create(:workflow,
                         type_id: type.id,
                         old_status: status,
                         new_status: status_2,
                         role: invalid_role)
    }

    shared_examples_for 'work package status transition' do
      describe 'valid' do
        before do
          valid_user_workflow

          work_package.status = status_2
        end

        it { expect(work_package.save).to be_truthy }
      end

      describe 'invalid' do
        before do
          invalid_user_workflow

          work_package.status = status_2
        end

        it { expect(work_package.save).to eq(invalid_result) }
      end

      describe 'non-existing' do
        before do work_package.status = status_2 end

        it { expect(work_package.save).to be_falsey }
      end
    end

    describe 'non-admin user' do
      before do allow(User).to receive(:current).and_return user end

      it_behaves_like 'work package status transition' do
        let(:invalid_result) { false }
      end
    end

    describe 'admin user' do
      let(:admin) { FactoryGirl.create(:admin) }

      before do allow(User).to receive(:current).and_return admin end

      it_behaves_like 'work package status transition' do
        let(:invalid_result) { true }
      end
    end

    describe 'transition to non-existing status' do
      before do
        work_package.status_id = -1
        work_package.valid?
      end

      it 'should not have the error on the :status_id field' do
        expect(work_package.errors).not_to have_key(:status_id)
      end

      it 'has an error' do
        expect(work_package.errors[:status].count).to eql(1)
      end

      it 'has a blank error on the .status field' do
        expect(work_package.errors[:status].first)
          .to eql(I18n.t('activerecord.errors.messages.blank'))
      end
    end
  end

  describe '#new_statuses_allowed_to' do
    let(:role) { FactoryGirl.build_stubbed(:role) }
    let(:type) { FactoryGirl.build_stubbed(:type) }
    let(:user) { FactoryGirl.build_stubbed(:user) }
    let(:assignee_user) { FactoryGirl.build_stubbed(:user) }
    let(:author_user) { FactoryGirl.build_stubbed(:user) }
    let(:current_status) { FactoryGirl.build_stubbed(:status) }
    let(:work_package) do
      FactoryGirl.build_stubbed(:work_package,
                                assigned_to: assignee_user,
                                author: author_user,
                                status: current_status,
                                type: type)
    end
    let(:default_status) do
      status = FactoryGirl.build_stubbed(:status)

      allow(Status)
        .to receive(:default)
        .and_return(status)

      status
    end

    let(:roles) { [role] }

    before do
      default_status

      expect(user)
        .to receive(:roles_for_project)
        .with(work_package.project)
        .and_return(roles)
    end

    shared_examples_for 'new_statuses_allowed_to' do
      let(:base_scope) do
        current_status
          .new_statuses_allowed_to([role], type, author, assignee)
          .or(Status.where(id: current_status.id))
      end

      it 'returns a scope that returns current_status and those available by workflow' do
        expect(work_package.new_statuses_allowed_to(user).to_sql)
          .to eql base_scope.order_by_position.to_sql
      end

      it 'adds the default status when the parameter is set accordingly' do
        expected = base_scope.or(Status.where(id: Status.default.id)).order_by_position

        expect(work_package.new_statuses_allowed_to(user, true).to_sql)
          .to eql expected.to_sql
      end

      it 'removes closed statuses if blocked' do
        allow(work_package)
          .to receive(:blocked?)
          .and_return(true)

        expected = base_scope.where(is_closed: false).order_by_position

        expect(work_package.new_statuses_allowed_to(user).to_sql)
          .to eql expected.to_sql
      end
    end

    context 'with somebody else asking' do
      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { false }
      end
    end

    context 'with the author asking' do
      let(:user) { author_user }

      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { true }
        let(:assignee) { false }
      end
    end

    context 'with the assignee asking' do
      let(:user) { assignee_user }

      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { true }
      end
    end

    context 'with the assignee changing and asking as new assignee' do
      before do
        work_package.assigned_to = user
      end

      # is using the former assignee
      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { false }
      end
    end
  end
end
