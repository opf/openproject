#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe WorkPackage, 'status', type: :model do
  let(:status) { FactoryBot.create(:status) }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                       status: status)
  end

  it 'can read planning_elements w/ the help of the has_many association' do
    expect(WorkPackage.where(status_id: status.id).count).to eq(1)
    expect(WorkPackage.where(status_id: status.id).first).to eq(work_package)
  end

  describe '#readonly' do
    let(:status) { FactoryBot.create(:status, is_readonly: true) }

    context 'with EE', with_ee: %i[readonly_work_packages] do
      it 'marks work package as read only' do
        expect(work_package).to be_readonly_status
      end
    end

    context 'without EE' do
      it 'is not marked as read only' do
        expect(work_package).not_to be_readonly_status
      end
    end
  end

  describe '#new_statuses_allowed_to' do
    let(:role) { FactoryBot.build_stubbed(:role) }
    let(:type) { FactoryBot.build_stubbed(:type) }
    let(:user) { FactoryBot.build_stubbed(:user) }
    let(:assignee_user) { FactoryBot.build_stubbed(:user) }
    let(:author_user) { FactoryBot.build_stubbed(:user) }
    let(:current_status) { FactoryBot.build_stubbed(:status) }
    let(:work_package) do
      FactoryBot.build_stubbed(:work_package,
                                assigned_to: assignee_user,
                                author: author_user,
                                status: current_status,
                                type: type)
    end
    let(:default_status) do
      status = FactoryBot.build_stubbed(:status)

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
