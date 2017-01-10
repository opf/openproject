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
    let(:current_status) { FactoryGirl.build_stubbed(:status) }
    let(:work_package) do
      FactoryGirl.build_stubbed(:work_package,
                                status: current_status)
    end
    let(:other_status) { FactoryGirl.build_stubbed(:status) }
    let(:default_status) do
      status = FactoryGirl.build_stubbed(:status)

      allow(Status)
        .to receive(:default)
        .and_return(status)

      status
    end

    let(:roles) { [role] }

    before do
      expect(user)
        .to receive(:roles_for_project)
        .with(work_package.project)
        .and_return(roles)

      allow(current_status)
        .to receive(:find_new_statuses_allowed_to)
        .and_return([])
    end

    shared_examples_for 'new_statuses_allowed_to' do
      it 'returns the statuses' do
        expect(work_package.new_statuses_allowed_to(user))
          .to match_array([current_status, other_status])
      end

      it 'adds the default status when the parameter is set accordingly' do
        default_status

        expect(work_package.new_statuses_allowed_to(user, true))
          .to match_array([current_status, other_status, default_status])
      end

      it 'removes closed statuses if blocked' do
        other_status.is_closed = true

        allow(work_package)
          .to receive(:blocked?)
          .and_return(true)

        expect(work_package.new_statuses_allowed_to(user))
          .to match_array([current_status])
      end
    end

    context 'with somebody else asking' do
      before do
        allow(current_status)
          .to receive(:find_new_statuses_allowed_to)
          .with(roles, work_package.type, false, false)
          .and_return([other_status])
      end

      it_behaves_like 'new_statuses_allowed_to'
    end

    context 'with the author asking' do
      before do
        work_package.author = user

        allow(current_status)
          .to receive(:find_new_statuses_allowed_to)
          .with(roles, work_package.type, true, false)
          .and_return([other_status])
      end

      it_behaves_like 'new_statuses_allowed_to'
    end

    context 'with the assignee asking' do
      before do
        work_package.assigned_to_id = user.id

        allow(work_package)
          .to receive(:assigned_to_id_changed?)
          .and_return false

        allow(current_status)
          .to receive(:find_new_statuses_allowed_to)
          .with(roles, work_package.type, false, true)
          .and_return([other_status])
      end

      it_behaves_like 'new_statuses_allowed_to'
    end
  end
end
